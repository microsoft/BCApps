#pragma warning disable AA0247
codeunit 139932 "MDM Cross-Env Consumer Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibrarySalesLib: Codeunit "Library - Sales";

    [Test]
    procedure CrossEnvGetBySystemIdRoundTripsSourceRecord()
    var
        Customer: Record Customer;
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
        Found: Boolean;
    begin
        // [FEATURE] [AI test 0.4] [Master Data Management] [Cross-Environment]
        // [SCENARIO] The cross-env data source fetches a record over the transport and materializes it (fields included).
        Initialize();
        LibrarySalesLib.CreateCustomer(Customer);
        Customer.Name := CopyStr(LibraryRandomText(), 1, MaxStrLen(Customer.Name));
        Customer.Modify();

        // [GIVEN] a subsidiary configured for cross-env with the in-process (pass-through) transport
        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();

        // [WHEN] the record is fetched by SystemId
        Found := LibraryMasterDataMgt.DataSourceGetBySystemId(Database::Customer, Customer.SystemId, SourceRecordRef);

        // [THEN] the materialized record carries the same SystemId and field values
        Assert.IsTrue(Found, 'Cross-env GetBySystemId should find the source record');
        Assert.AreEqual(Customer.SystemId, SourceRecordRef.Field(SourceRecordRef.SystemIdNo()).Value(), 'Wrong SystemId materialized');
        Assert.AreEqual(Customer.Name, Format(SourceRecordRef.Field(Customer.FieldNo(Name)).Value()), 'Name should round-trip through the wire');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvGetModifiedSetMaterializesSourceChange()
    var
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
        Found: Boolean;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Cross-env GetModifiedSet pages the source feed over the transport and materializes the changes.
        Initialize();
        LibrarySalesLib.CreateCustomer(Customer);
        CreateMinimalCustomerMapping(IntegrationTableMapping);

        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();

        Found := LibraryMasterDataMgt.DataSourceGetModifiedSet(IntegrationTableMapping, '', SourceRecordRef);

        Assert.IsTrue(Found, 'Cross-env GetModifiedSet should return source records');
        Assert.IsTrue(ContainsSystemId(SourceRecordRef, Customer.SystemId), 'Materialized set should contain the seeded customer');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvErrorsWhenSourceTableUnavailable()
    var
        Customer: Record Customer;
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A tableAvailable:false response surfaces as a clear synchronization error.
        Initialize();
        LibrarySalesLib.CreateCustomer(Customer);
        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();
        InProcessTransport.SetCannedResponse('{"tableId":18,"tableAvailable":false,"records":[],"hasMore":false}');

        asserterror LibraryMasterDataMgt.DataSourceGetBySystemId(Database::Customer, Customer.SystemId, SourceRecordRef);
        Assert.ExpectedError('not available on the source environment');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvErrorsWhenSourceTableNotIndexed()
    var
        Customer: Record Customer;
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] An indexed:false response (too-large unindexed table) asks for the composite key.
        Initialize();
        LibrarySalesLib.CreateCustomer(Customer);
        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();
        InProcessTransport.SetCannedResponse('{"tableId":18,"tableAvailable":true,"indexed":false,"records":[],"hasMore":false}');

        asserterror LibraryMasterDataMgt.DataSourceGetBySystemId(Database::Customer, Customer.SystemId, SourceRecordRef);
        Assert.ExpectedError('Add a key on SystemModifiedAt and SystemId');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvErrorsWhenFieldsUnavailable()
    var
        Customer: Record Customer;
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] An unavailableFields response halts the table with a clear synchronization error.
        Initialize();
        LibrarySalesLib.CreateCustomer(Customer);
        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();
        InProcessTransport.SetCannedResponse('{"tableId":18,"tableAvailable":true,"unavailableFields":[5],"records":[],"hasMore":false}');

        asserterror LibraryMasterDataMgt.DataSourceGetBySystemId(Database::Customer, Customer.SystemId, SourceRecordRef);
        Assert.ExpectedError('do not exist on table');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvGetModifiedBatchResumesAcrossRuns()
    var
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        PagingConfig: Codeunit "MDM Test Paging Config";
        SourceRecordRef: RecordRef;
        SeededSystemId: Guid;
        SeededSystemIds: List of [Guid];
        CollectedSystemIds: List of [Guid];
        Watermark: DateTime;
        Cursor: Text;
        EndCursor: Text;
        Index: Integer;
        Runs: Integer;
        HasMore: Boolean;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A page-capped batch (MaxPages=1) drains a multi-page change set across several runs, resuming
        //            from the returned cursor each time, and covers every source record exactly once.
        Initialize();

        // [GIVEN] five source customers created strictly after a captured watermark (so only they are in the feed)
        Watermark := CurrentDateTime();
        Sleep(100);
        for Index := 1 to 5 do begin
            LibrarySalesLib.CreateCustomer(Customer);
            SeededSystemIds.Add(Customer.SystemId);
        end;
        CreateMinimalCustomerMapping(IntegrationTableMapping);
        IntegrationTableMapping."Synch. Modified On Filter" := Watermark;
        IntegrationTableMapping.Modify();

        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();
        PagingConfig.Activate(2); // two records per page

        // [WHEN] the batch is drained one page per run, resuming from the returned cursor
        Cursor := '';
        repeat
            LibraryMasterDataMgt.DataSourceGetModifiedBatch(IntegrationTableMapping, '', Cursor, 1, SourceRecordRef, EndCursor, HasMore);
            CollectSystemIds(SourceRecordRef, CollectedSystemIds);
            Cursor := EndCursor;
            Runs += 1;
        until not HasMore;

        // [THEN] it took multiple runs and every seeded record was returned exactly once
        Assert.IsTrue(Runs >= 3, 'A 5-record set at 2/page and 1 page/run should need at least three runs');
        Assert.AreEqual(5, CollectedSystemIds.Count(), 'Every seeded record should be returned exactly once across runs');
        foreach SeededSystemId in SeededSystemIds do
            Assert.IsTrue(CollectedSystemIds.Contains(SeededSystemId), 'Every seeded record should be covered by the resumed batches');

        PagingConfig.Deactivate();
        CleanUp();
    end;

    local procedure Initialize()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        InProcessTransport: Codeunit "MDM In-Process Transport";
    begin
        InProcessTransport.Deactivate();
        if not MasterDataManagementSetup.Get() then begin
            MasterDataManagementSetup.Init();
            MasterDataManagementSetup.Insert();
        end;
        MasterDataManagementSetup."Source Environment Name" := '';
        MasterDataManagementSetup.Modify(false);
    end;

    local procedure CleanUp()
    var
        InProcessTransport: Codeunit "MDM In-Process Transport";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        PagingConfig: Codeunit "MDM Test Paging Config";
    begin
        InProcessTransport.Deactivate();
        PagingConfig.Deactivate();
        LibraryMasterDataMgt.SetSourceEnvironmentName('');
    end;

    local procedure CreateMinimalCustomerMapping(var IntegrationTableMapping: Record "Integration Table Mapping")
    begin
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := CopyStr('MDMXENV' + Format(LibraryRandomInt()), 1, MaxStrLen(IntegrationTableMapping.Name));
        IntegrationTableMapping.Type := IntegrationTableMapping.Type::"Master Data Management";
        IntegrationTableMapping."Table ID" := Database::Customer;
        IntegrationTableMapping."Integration Table ID" := Database::Customer;
        IntegrationTableMapping."Integration Table UID Fld. No." := 2000000000; // SystemId
        IntegrationTableMapping."Int. Tbl. Modified On Fld. No." := 2000000003; // SystemModifiedAt
        IntegrationTableMapping."Delete After Synchronization" := false;
        IntegrationTableMapping.Insert();
    end;

    local procedure ContainsSystemId(var SourceRecordRef: RecordRef; SystemIdValue: Guid): Boolean
    begin
        if SourceRecordRef.FindSet() then
            repeat
                if Format(SourceRecordRef.Field(SourceRecordRef.SystemIdNo()).Value()) = Format(SystemIdValue) then
                    exit(true);
            until SourceRecordRef.Next() = 0;
        exit(false);
    end;

    local procedure CollectSystemIds(var SourceRecordRef: RecordRef; var CollectedSystemIds: List of [Guid])
    var
        SystemIdValue: Guid;
    begin
        if SourceRecordRef.FindSet() then
            repeat
                SystemIdValue := SourceRecordRef.Field(SourceRecordRef.SystemIdNo()).Value();
                if not CollectedSystemIds.Contains(SystemIdValue) then
                    CollectedSystemIds.Add(SystemIdValue);
            until SourceRecordRef.Next() = 0;
    end;

    local procedure LibraryRandomText(): Text
    var
        LibraryRandomCu: Codeunit "Library - Random";
    begin
        exit(LibraryRandomCu.RandText(20));
    end;

    local procedure LibraryRandomInt(): Integer
    var
        LibraryRandomCu: Codeunit "Library - Random";
    begin
        exit(LibraryRandomCu.RandIntInRange(1, 999999));
    end;
}
