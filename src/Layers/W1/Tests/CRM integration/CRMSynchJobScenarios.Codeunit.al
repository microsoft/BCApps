codeunit 139169 "CRM Synch. Job Scenarios"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Integration Table Synch.]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        IntTableSynchSubscriber: Codeunit "Int. Table Synch. Subscriber";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SynchZeroItemsPopulatesDefaultSynchDirectionToMatchMapping()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        // [FEATURE] [Direction]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // [GIVEN] A source of 0 records
        LibraryCRMIntegration.CreateIntegrationTableData(0, 0);
        // [GIVEN] A mapping with direction ToIntegrationTable
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping.Modify();
        // [WHEN] Executing scheduled synch.
        IntegrationSynchJob.DeleteAll();
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        // [THEN] Job direction matches the Integration Table Mapping direction.
        IntegrationSynchJob.FindLast();
        Assert.AreEqual(
          IntegrationSynchJob."Synch. Direction"::ToIntegrationTable, IntegrationSynchJob."Synch. Direction",
          'Expected the direction to match the mapping ToIntegrationTable');

        // [GIVEN] A source of 0 records
        LibraryCRMIntegration.CreateIntegrationTableData(0, 0);
        // [GIVEN] A mapping with direction FromIntegrationTable
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping.Modify();
        // [WHEN] Executing scheduled synch.
        IntegrationSynchJob.DeleteAll();
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        // [THEN] Job direction matches the Integration Table Mapping direction.
        IntegrationSynchJob.FindLast();
        Assert.AreEqual(
          IntegrationSynchJob."Synch. Direction"::FromIntegrationTable, IntegrationSynchJob."Synch. Direction",
          'Expected the direction to match the mapping FromIntegrationTable');

        // [GIVEN] A source of 0 records
        LibraryCRMIntegration.CreateIntegrationTableData(0, 0);
        // [GIVEN] A mapping with direction Bidrectional
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;
        IntegrationTableMapping.Modify();
        // [WHEN] Executing scheduled synch.
        IntegrationSynchJob.DeleteAll();
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        // [THEN] Two Jobs are created: the first with Direction "ToIntegrationTable" and the second with Direction "FromIntegrationTable"
        Assert.RecordCount(IntegrationSynchJob, 2);
        IntegrationSynchJob.SetRange("Synch. Direction", IntegrationSynchJob."Synch. Direction"::ToIntegrationTable);
        Assert.RecordCount(IntegrationSynchJob, 1);
        IntegrationSynchJob.SetRange("Synch. Direction", IntegrationSynchJob."Synch. Direction"::FromIntegrationTable);
        Assert.RecordCount(IntegrationSynchJob, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchFilteredViewToCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        UnitOfMeasure: Record "Unit of Measure";
        TestIntegrationTable: Record "Test Integration Table";
        CRMIntegrationRecord: Record "CRM Integration Record";
        TableFilter: FilterPageBuilder;
        TestUid: Guid;
    begin
        // [FEATURE] [Table Filter]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A source of 3 records
        // [GIVEN] A mapping with a filter that limits the source to 2 records
        LibraryCRMIntegration.CreateIntegrationTableData(3, 0);
        // Create filter excluding the last row.
        UnitOfMeasure.FindLast();
        UnitOfMeasure.SetFilter(Code, '<>%1', UnitOfMeasure.Code);
        TableFilter.AddTable(UnitOfMeasure.TableCaption(), DATABASE::"Unit of Measure");
        TableFilter.SetView(UnitOfMeasure.TableCaption(), UnitOfMeasure.GetView());

        UnitOfMeasure.Reset();
        UnitOfMeasure.SetView(TableFilter.GetView(UnitOfMeasure.TableCaption(), true));
        Assert.AreEqual(2, UnitOfMeasure.Count, 'Expected the filter to limit the rowcount');

        // [GIVEN] The mapping allows not only synching coupled records, but also record creation
        IntegrationTableMapping.SetTableFilter(TableFilter.GetView(UnitOfMeasure.TableCaption(), true));
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        // [WHEN] Scheduled synch executes
        // [THEN] 2 records should be created in CRM
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        Assert.AreEqual(2, TestIntegrationTable.Count, 'Expected 2 records to be synchronized');

        // [GIVEN] The mapping filter is blank
        IntegrationTableMapping.SetTableFilter('');
        IntegrationTableMapping.Modify();

        // [GIVEN] The last record, not included in the filter, is coupled and modified.
        TestUid := CreateGuid();
        TestIntegrationTable.Reset();
        TestIntegrationTable.Init();
        TestIntegrationTable."Integration Uid" := TestUid;
        TestIntegrationTable.Insert();
        // Create coupling
        UnitOfMeasure.Reset();
        UnitOfMeasure.FindLast();
        CRMIntegrationRecord.CoupleCRMIDToRecordID(
          TestIntegrationTable."Integration Uid", UnitOfMeasure.RecordId);
        // Ensure it looks new
        Sleep(200);
        UnitOfMeasure.Find();
        UnitOfMeasure.Description := 'abc';
        UnitOfMeasure.Modify();

        // [WHEN] Scheduled synch executes
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);

        // [THEN] The coupled record outside the original filter is updated
        UnitOfMeasure.Reset();
        UnitOfMeasure.FindLast();
        // Refresh row data
        TestIntegrationTable.Reset();
        TestIntegrationTable.Get(TestUid);
        // Verify the code field was transfered
        Assert.AreEqual(UnitOfMeasure.Description, TestIntegrationTable."Integration Field Value", 'Expected the value be synchronized');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchFilteredViewFromCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        UnitOfMeasure: Record "Unit of Measure";
        TestIntegrationTable: Record "Test Integration Table";
        TableFilter: FilterPageBuilder;
    begin
        // [FEATURE] [Integration Table Filter]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);
        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A CRM source of 3 records
        // [GIVEN] A mapping with a CRM filter that limits the source to 1 records
        // [GIVEN] A mapping allowing record creation
        LibraryCRMIntegration.CreateIntegrationTableData(0, 3);
        // Create filter only including the last row.
        TestIntegrationTable.FindLast();
        TestIntegrationTable.SetFilter("Integration Uid", '=%1', TestIntegrationTable."Integration Uid");
        TableFilter.AddTable(TestIntegrationTable.TableCaption(), DATABASE::"Test Integration Table");
        TableFilter.SetView(TestIntegrationTable.TableCaption(), TestIntegrationTable.GetView());

        TestIntegrationTable.Reset();
        TestIntegrationTable.SetView(TableFilter.GetView(TestIntegrationTable.TableCaption(), true));
        Assert.AreEqual(1, TestIntegrationTable.Count, 'Expected the filter to limit the rowcount');

        IntegrationTableMapping.SetIntegrationTableFilter(TableFilter.GetView(TestIntegrationTable.TableCaption(), true));
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        // [WHEN] Scheduled synch executes
        // [THEN] 1 records should be created in NAV
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        Assert.AreEqual(1, UnitOfMeasure.Count, 'Expected 1 records to be synchronized');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSynchFromCRMIncludesChangesByIntegrationUser()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        UnitOfMeasure: Record "Unit of Measure";
        TestIntegrationTable: Record "Test Integration Table";
        CRMSystemuser: Record "CRM Systemuser";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);
        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A CRM source of 3 records
        // [GIVEN] A mapping with a CRM filter that limits the source to 1 records
        // [GIVEN] A mapping allowing record creation
        LibraryCRMIntegration.CreateIntegrationTableData(0, 3);

        // [GIVEN] 2 of 3 records are modified by the integration system user
        CRMConnectionSetup.FindFirst();
        CRMSystemuser.Get(CRMConnectionSetup.GetIntegrationUserID());
        TestIntegrationTable.FindSet();
        TestIntegrationTable.ModifiedBy := CRMSystemuser.SystemUserId;
        TestIntegrationTable.Modify();
        TestIntegrationTable.Next();
        TestIntegrationTable.ModifiedBy := CRMSystemuser.SystemUserId;
        TestIntegrationTable.Modify();

        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        // [WHEN] Scheduled synch executes
        // [THEN] 3 records should be created in NAV
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        Assert.AreEqual(3, UnitOfMeasure.Count, 'Expected 3 records to be synchronized');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchOnlyCoupledRecordsMapping()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        UncoupledCRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        NumCustomerRecordsBeforeSynch: Integer;
    begin
        // [GIVEN] A valid and registered CRM Connection Setup
        Initialize();

        // [GIVEN] A mapping allowing synch only for coupled records (the default setting)
        ResetDefaultCRMSetupConfiguration();

        // [GIVEN] A CRM source with two records, one coupled and one not coupled
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(UncoupledCRMAccount);

        // [GIVEN] The coupled record has different data on both sides
        // This is the default at the moment because both are randomly generated, but just in case:
        CRMAccount.Name := 'New Name';
        CRMAccount.Modify();

        // Make sure synchronization happens from CRM to NAV
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping.Modify();

        // [WHEN] Scheduled synch executes
        NumCustomerRecordsBeforeSynch := Customer.Count();
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);

        // [THEN] The coupled record should be updated
        Customer.Get(Customer."No.");
        Assert.AreEqual(CRMAccount.Name, Customer.Name,
          'Expected the coupled Customer to be updated with data from CRM');

        // [THEN] No new record should be created
        Assert.AreEqual(NumCustomerRecordsBeforeSynch, Customer.Count,
          'No new Customer should be created from the uncoupled Account');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchInvalidViewCausesError()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Filter] [Integration Table Filter]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);
        LibraryCRMIntegration.CreateIntegrationTableData(2, 2);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A mapping with direction = ToIntegrationTable
        // [GIVEN] A mapping with an invalid table filter and valid integration table filter
        IntegrationTableMapping.SetTableFilter('BADDATA');
        IntegrationTableMapping.SetIntegrationTableFilter('');
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping.Modify();
        // [WHEN] Scheduled synch executes
        // [THEN] An error should occur
        asserterror CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A mapping with direction = FromIntegrationTable
        // [GIVEN] A mapping with an valid table filter and invalid integration table filter
        IntegrationTableMapping.SetTableFilter('');
        IntegrationTableMapping.SetIntegrationTableFilter('More BADDATA');
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping.Modify();
        // [WHEN] Scheduled synch executes
        // [THEN] An error should occur
        asserterror CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchUpdatesLastSynchModifiedOnWhenDataChanges()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        UnitOfMeasure: Record "Unit of Measure";
        TestIntegrationTable: Record "Test Integration Table";
        ExpectedLatestDateTime: DateTime;
    begin
        // [FEATURE] [Modified On]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A CRM source of 2 records that can be copied to NAV
        LibraryCRMIntegration.CreateIntegrationTableData(0, 2);
        ExpectedLatestDateTime := CreateDateTime(Today + 1, Time);
        TestIntegrationTable.FindLast();
        TestIntegrationTable."Integration Modified Field" := ExpectedLatestDateTime;
        TestIntegrationTable.Modify();

        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := 0DT;
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        // [WHEN] Scheduled synch executes
        // [THEN] The mapping Synch Integration Table modified On Filter should be updated with the latest modified on datetime of the two synched records
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        Assert.AreEqual(2, UnitOfMeasure.Count, 'Expected 2 records to be synchronized');

        IntegrationTableMapping.Get(IntegrationTableMapping.Name);
        Assert.IsTrue(IntegrationTableMapping."Synch. Modified On Filter" <= ExpectedLatestDateTime, 'Expected the latest modified on value not to go into the mapping "Synch. Modified On Filter" value.');

        UnitOfMeasure.Reset();
        TestIntegrationTable.Reset();

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A NAV source of 2 records that can be copied to CRM
        LibraryCRMIntegration.CreateIntegrationTableData(2, 0);
        UnitOfMeasure.FindLast();
        UnitOfMeasure.Description := 'xyz';
        ExpectedLatestDateTime := CurrentDateTime() + 200;
        Sleep(200);
        UnitOfMeasure.Modify();

        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping."Synch. Modified On Filter" := 0DT;
        IntegrationTableMapping.Modify();

        // [WHEN] Scheduled synch executes
        // [THEN] The mapping Synch Integration Table modified On Filter should be updated with the latest modified on datetime of the two synched records
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        Assert.AreEqual(2, TestIntegrationTable.Count, 'Expected 2 records to be synchronized');

        IntegrationTableMapping.Get(IntegrationTableMapping.Name);
        Assert.AreEqual(
          ExpectedLatestDateTime, IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.",
          'Expected the latest modified on value to go into the mapping "Synch. Int. Tbl. Mod. On Fltr." value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchUpdatesLastSynchModifiedOnWhenNoDataChanges()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TestIntegrationTable: Record "Test Integration Table";
        LastSynchModifiedOn: DateTime;
    begin
        // [FEATURE] [Modified On]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A CRM source of 2 records already synched to NAV
        LibraryCRMIntegration.CreateIntegrationTableData(0, 2);
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        // [GIVEN] CRM sources are updated but not in mapped fields.
        TestIntegrationTable.ModifyAll("Integration Modified Field", CreateDateTime(CalcDate('<+1D>', Today), Time));
        IntegrationTableMapping.Get(IntegrationTableMapping.Name);
        LastSynchModifiedOn := IntegrationTableMapping."Synch. Modified On Filter";
        Assert.AreNotEqual(0DT, LastSynchModifiedOn,
          'Did not expect the synch. integration table last modified on filter to be empty');
        Sleep(2000);
        // [WHEN] Scheduled synch executes
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        // [THEN] The mapping should be updated with the latest modified date.
        IntegrationTableMapping.Get(IntegrationTableMapping.Name);
        Assert.IsTrue(IntegrationTableMapping."Synch. Modified On Filter" >= LastSynchModifiedOn,
          'Did expect integration table last modified on filter to change when running the same synch. twice');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchDoesNotUpdateLastSynchModifiedOnWhenRowsAreSynched()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Modified On]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A NAV source of 2 records already synched to CRM
        LibraryCRMIntegration.CreateIntegrationTableData(2, 0);
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);

        IntegrationTableMapping.Get(IntegrationTableMapping.Name);
        Assert.AreNotEqual(
          0DT, IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.", 'Did not expect the synch. last modified on filter to be empty');
        IntegrationTableMapping."Synch. Modified On Filter" := 0DT;
        IntegrationTableMapping.Modify();
        // [WHEN] Scheduled synch executes
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        // [THEN] The mapping should NOT be updated with the latest modified date.
        IntegrationTableMapping.Get(IntegrationTableMapping.Name);
        Assert.AreEqual(
          0DT, IntegrationTableMapping."Synch. Modified On Filter",
          'Did not expect the synch. last modified on filter to change when running the same synch. twice');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BidirectionalSynchCanUpdateDataInBothSystems()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        UnitOfMeasure: Record "Unit of Measure";
        TestIntegrationTable: Record "Test Integration Table";
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        // [FEATURE] [Direction]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A NAV source of 2 records
        // [GIVEN] A CRM source of 2 records
        // [GIVEN] A mapping with direction set to bidirectional
        // [GIVEN] A mapping allowing record creation
        LibraryCRMIntegration.CreateIntegrationTableData(2, 2);
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        // [WHEN] Scheduled synch executes
        // [THEN] 4 records should exist in both system
        IntegrationSynchJob.DeleteAll();
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        Assert.AreEqual(4, TestIntegrationTable.Count, 'Expected the Integration Table row count to be 4');
        Assert.AreEqual(4, UnitOfMeasure.Count, 'Expected the Unit Of Measure row count to be 4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BidirectionalSynchCreatesTwoJobs()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        // [FEATURE] [Direction]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);
        LibraryCRMIntegration.CreateIntegrationTableData(2, 2);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A mapping with direction = ToIntegrationTable
        // [GIVEN] A mapping with an invalid table filter and valid integration table filter
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;
        IntegrationTableMapping.Modify();
        // [WHEN] Scheduled synch executes
        // [THEN] Two jobs should be created
        IntegrationSynchJob.DeleteAll();
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        Assert.AreEqual(2, IntegrationSynchJob.Count, 'Expected a bidirectional mapping synch. to create two jobs');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchUncoupledCRMAccountToCustomer()
    var
        CRMAccount: Record "CRM Account";
    begin
        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] CRMAccount source with only 1 uncoupled customer
        // [WHEN] Job Queue kicks off a Customer sync job
        // [THEN] 1. customer should be created in NAV
        // [THEN] Customer is coupled to CRM Account
        // [THEN] Synch. Job entry is created with 1 inserted.
        Initialize();

        CRMAccount.DeleteAll();
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        SyncCRMAccountToCustomer(CRMAccount, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncCoupledCRMAccountToCustomer()
    var
        CRMAccount: Record "CRM Account";
    begin
        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] CRMAccount source with only 1 coupled customer
        // [GIVEN] A Customer mapping allowing record creation
        // [WHEN] Job Queue kicks off a Customer sync job
        // [THEN] 1. customer should be modified in NAV
        // [THEN] Customer remains coupled to CRM Account
        // [THEN] Synch. Job entry is created with 1 modified.
        Initialize();
        CRMAccount.DeleteAll();
        // Setup
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        CRMAccount.ModifiedOn := CreateDateTime(CalcDate('<-1Y>', Today), Time);
        CRMAccount.Modify();
        SyncCRMAccountToCustomer(CRMAccount, 1, 0);

        // Run
        CRMAccount.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CRMAccount.Name)), 1, MaxStrLen(CRMAccount.Name));
        CRMAccount.ModifiedOn := CreateDateTime(CalcDate('<+2D>', Today), Time);
        CRMAccount.Modify();

        SyncCRMAccountToCustomer(CRMAccount, 0, 1);
    end;

    [Normal]
    local procedure SyncCRMAccountToCustomer(var CRMAccount: Record "CRM Account"; ExpectedInserted: Integer; ExpectedModified: Integer)
    var
        CoupledCustomer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CreatedRecordID: RecordID;
    begin
        // Setup
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.SetRange("Table ID", DATABASE::Customer);
        IntegrationTableMapping.FindFirst();
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping.SetIntegrationTableFilter('');
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
        JobQueueEntry.FindFirst();

        IntegrationSynchJob.DeleteAll();

        // Run
        CODEUNIT.Run(CODEUNIT::"Integration Synch. Job Runner", JobQueueEntry);

        // Validate
        Assert.IsTrue(IntegrationSynchJob.FindSet(), 'Expected job log entries');
        repeat
            IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", IntegrationSynchJob.ID);
            if IntegrationSynchJobErrors.FindFirst() then
                Assert.Fail('One or more job errors was found: ' + IntegrationSynchJobErrors.Message);
        until IntegrationSynchJob.Next() = 0;

        IntegrationSynchJob.SetFilter("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationSynchJob.FindSet();
        if (IntegrationSynchJob.Inserted <> ExpectedInserted) and (IntegrationSynchJob.Modified <> ExpectedModified) then
            IntegrationSynchJob.Next();
        Assert.AreEqual(ExpectedInserted, IntegrationSynchJob.Inserted, 'Expected the log to reflect inserted row(s)');
        Assert.AreEqual(ExpectedModified, IntegrationSynchJob.Modified, 'Expected the log to reflect modified row(s)');

        Assert.IsTrue(
          CRMIntegrationRecord.FindRecordIDFromID(
            CRMAccount.AccountId,
            DATABASE::Customer,
            CreatedRecordID),
          'Expected to find a coupled record');
        Assert.IsTrue(CoupledCustomer.Get(CreatedRecordID), 'Expected couple customer to exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BrokenConnectionOnRunIntegrationTableSync()
    var
        CRMSystemuser: Record "CRM Systemuser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 264617] Broken connection causes incremented "No. of Attempts to Run" on job queue entry.
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        ResetDefaultCRMSetupConfiguration();

        // [GIVEN] CRM Connection is broken
        CRMSystemuser.DeleteAll();

        // [WHEN] Sync job for customer is being run
        IntegrationTableMapping.SetRange("Table ID", DATABASE::Customer);
        IntegrationTableMapping.FindFirst();
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
        JobQueueEntry.FindFirst();
        asserterror LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        LibraryJobQueue.RunJobQueueErrorHandler(JobQueueEntry);

        // [THEN] Job queue entry in status Ready
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Ready);
        // [THEN] Job queue entry "No. of Attempts to Run" = 1
        JobQueueEntry.TestField("No. of Attempts to Run", 1);
    end;

    local procedure Initialize()
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        ResetDefaultCRMSetupConfiguration();

        if IsInitialized then
            exit;
        IsInitialized := true;
        if BindSubscription(IntTableSynchSubscriber) then;
    end;

    local procedure ResetDefaultCRMSetupConfiguration()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ClientSecret: Text;
    begin
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;
}

