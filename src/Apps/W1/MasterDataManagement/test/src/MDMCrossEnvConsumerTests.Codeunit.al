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
        WizardPrivacyNoticeOpenCount: Integer;
        InvalidSourceHostErr: Label 'not a valid Business Central endpoint', Locked = true;

    [Test]
    procedure CrossEnvGetBySystemIdRoundTripsSourceRecord()
    var
        Customer: Record Customer;
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
        MaterializedModifiedAt: DateTime;
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

        // [THEN] the materialized record carries the same SystemId and field values, and the source SystemModifiedAt
        // watermark survives materialization (the sync loop reads it via the side cache, not the temp row)
        Assert.IsTrue(Found, 'Cross-env GetBySystemId should find the source record');
        Assert.AreEqual(Customer.SystemId, SourceRecordRef.Field(SourceRecordRef.SystemIdNo()).Value(), 'Wrong SystemId materialized');
        Assert.AreEqual(Customer.Name, Format(SourceRecordRef.Field(Customer.FieldNo(Name)).Value()), 'Name should round-trip through the wire');
        Assert.IsTrue(LibraryMasterDataMgt.TryGetSourceWatermark(Customer.SystemId, MaterializedModifiedAt), 'Source watermark should be cached during materialization');
        Assert.AreEqual(Customer.SystemModifiedAt, MaterializedModifiedAt, 'Source SystemModifiedAt should survive materialization');

        CleanUp();
    end;

    [Test]
    procedure HttpTransportRejectsNonBusinessCentralHosts()
    var
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment] [Security]
        // [SCENARIO] The source-host allow-list accepts only the exact HTTPS Business Central API hosts (SSRF guard).
        Initialize();

        // [GIVEN] the exact Business Central API hosts (production and TIE) over HTTPS [THEN] validation passes
        LibraryMasterDataMgt.ValidateHttpTransportSourceHost('https://api.businesscentral.dynamics.com/v2.0/CRONUS/Production');
        LibraryMasterDataMgt.ValidateHttpTransportSourceHost('https://api.businesscentral.dynamics-tie.com/v2.0/CRONUS/Sandbox');

        // [GIVEN] a non-HTTPS scheme [THEN] validation is rejected
        asserterror LibraryMasterDataMgt.ValidateHttpTransportSourceHost('http://api.businesscentral.dynamics.com/v2.0/CRONUS/Production');
        Assert.ExpectedError(InvalidSourceHostErr);

        // [GIVEN] any non-standard dynamics.com host (e.g. an Embed/ISV per-cluster hostname) [THEN] validation is rejected
        asserterror LibraryMasterDataMgt.ValidateHttpTransportSourceHost('https://myenv.api.bc.dynamics.com');
        Assert.ExpectedError(InvalidSourceHostErr);

        // [GIVEN] a subdomain of the allowed host [THEN] validation is rejected (exact host only)
        asserterror LibraryMasterDataMgt.ValidateHttpTransportSourceHost('https://sub.api.businesscentral.dynamics.com');
        Assert.ExpectedError(InvalidSourceHostErr);

        // [GIVEN] a host outside the allow-list [THEN] validation is rejected
        asserterror LibraryMasterDataMgt.ValidateHttpTransportSourceHost('https://evil.example.com');
        Assert.ExpectedError(InvalidSourceHostErr);

        // [GIVEN] a look-alike host that only embeds the allowed host as a non-final label [THEN] validation is rejected
        asserterror LibraryMasterDataMgt.ValidateHttpTransportSourceHost('https://api.businesscentral.dynamics.com.evil.example.com');
        Assert.ExpectedError(InvalidSourceHostErr);

        CleanUp();
    end;

    [Test]
    procedure CrossEnvTransferBlockedUntilPrivacyNoticeApproved()
    var
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        // [FEATURE] [AI test 0.4] [Master Data Management] [Cross-Environment] [Privacy]
        // [SCENARIO] Cross-env data transfer is gated on the privacy notice: blocked until approved, allowed after.
        Initialize();

        // [GIVEN] the cross-environment privacy notice is not approved
        PrivacyNotice.SetApprovalState(LibraryMasterDataMgt.PrivacyNoticeId(), "Privacy Notice Approval State"::Disagreed);

        // [THEN] the gate reports not approved and the transport check fails closed
        Assert.IsFalse(LibraryMasterDataMgt.PrivacyNoticeIsApproved(), 'Gate should report not approved before consent');
        asserterror LibraryMasterDataMgt.PrivacyNoticeCheckApproved();
        Assert.ExpectedError('privacy notice to be approved');

        // [WHEN] the admin approves the notice
        PrivacyNotice.SetApprovalState(LibraryMasterDataMgt.PrivacyNoticeId(), "Privacy Notice Approval State"::Agreed);

        // [THEN] the gate reports approved and the transport check passes
        Assert.IsTrue(LibraryMasterDataMgt.PrivacyNoticeIsApproved(), 'Gate should report approved after consent');
        LibraryMasterDataMgt.PrivacyNoticeCheckApproved();

        // reset approval so it does not leak into later tests
        PrivacyNotice.SetApprovalState(LibraryMasterDataMgt.PrivacyNoticeId(), "Privacy Notice Approval State"::Disagreed);
        CleanUp();
    end;

    [Test]
    procedure CrossEnvSyncSurfacesSourceConsentRequired()
    var
        Customer: Record Customer;
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment] [Privacy]
        // [SCENARIO] When the source hasn't approved sharing, the subsidiary sync surfaces a clear, actionable error
        //            (pointing at the source admin) rather than a raw transport failure.
        Initialize();
        LibrarySalesLib.CreateCustomer(Customer);
        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();
        LibraryMasterDataMgt.PrivacyNoticeResetApproval(); // the (in-process) source has not consented

        asserterror LibraryMasterDataMgt.DataSourceGetBySystemId(Database::Customer, Customer.SystemId, SourceRecordRef);
        Assert.ExpectedError('has not approved sharing its master data');

        CleanUp();
    end;

    [Test]
    [HandlerFunctions('PrivacyNoticeModalHandler')]
    procedure WizardConsentOpensPrivacyNotice()
    var
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        ConnectionWizard: TestPage "MDM Connection Details";
    begin
        // [FEATURE] [AI test 0.4] [Master Data Management] [Cross-Environment] [Privacy]
        // [SCENARIO] Choosing Next on the Welcome step opens the platform privacy notice - a regression guard that the
        // wizard actually calls ConfirmApproval (the handler below fires only if the notice dialog is shown).
        Initialize();

        // [GIVEN] the privacy notice has no recorded decision, so continuing past Welcome must prompt it
        LibraryMasterDataMgt.PrivacyNoticeResetApproval();
        WizardPrivacyNoticeOpenCount := 0;

        // [WHEN] the admin chooses Next on the Welcome step
        ConnectionWizard.OpenEdit();
        ConnectionWizard.ActionNext.Invoke();
        ConnectionWizard.Close();

        // [THEN] the privacy-notice dialog was shown exactly once - proving the wizard invoked ConfirmApproval
        Assert.AreEqual(1, WizardPrivacyNoticeOpenCount, 'Choosing Next on the Welcome step should open the privacy notice exactly once (call ConfirmApproval)');

        LibraryMasterDataMgt.PrivacyNoticeResetApproval();
        CleanUp();
    end;

    [Test]
    procedure CrossEnvGetByUidFilterAndGetByIdMaterializeSourceRecords()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
        UidFilter: Text;
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment]
        // [SCENARIO] Cross-env GetByUidFilter (pipe-split selector) and GetById (variant->SystemId) fetch source records.
        Initialize();
        LibrarySalesLib.CreateCustomer(Customer1);
        LibrarySalesLib.CreateCustomer(Customer2);
        CreateMinimalCustomerMapping(IntegrationTableMapping);
        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();

        // [GIVEN] a pipe-delimited UID filter of two source SystemIds
        UidFilter := Format(Customer1.SystemId) + '|' + Format(Customer2.SystemId);

        // [WHEN] fetched via the cross-env UID filter [THEN] both records materialize (exercises ParseSystemIds pipe-split)
        Assert.IsTrue(LibraryMasterDataMgt.DataSourceGetByUidFilter(IntegrationTableMapping, UidFilter, SourceRecordRef), 'GetByUidFilter should return records');
        Assert.IsTrue(ContainsSystemId(SourceRecordRef, Customer1.SystemId), 'UID filter should include the first customer');
        Assert.IsTrue(ContainsSystemId(SourceRecordRef, Customer2.SystemId), 'UID filter should include the second customer');

        // [WHEN] fetched via GetById with a text SystemId [THEN] the record materializes (exercises the variant->SystemId conversion)
        Assert.IsTrue(LibraryMasterDataMgt.DataSourceGetById(IntegrationTableMapping, Format(Customer1.SystemId), SourceRecordRef), 'GetById should return the record');
        Assert.AreEqual(1, SourceRecordRef.Count(), 'GetById should return exactly one record');
        Assert.IsTrue(ContainsSystemId(SourceRecordRef, Customer1.SystemId), 'GetById should include the requested customer');

        CleanUp();
    end;

    [Test]
    procedure HttpTransportUnwrapsODataValueEnvelope()
    var
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment]
        // [SCENARIO] The HTTP transport unwraps the ODataV4 { value: <inner> } envelope and passes other bodies through.
        Initialize();

        // [GIVEN] an OData action envelope [THEN] the inner value is returned
        Assert.AreEqual('{"records":[]}', LibraryMasterDataMgt.UnwrapHttpTransportODataValue('{"@odata.context":"x","value":"{\"records\":[]}"}'), 'Envelope value should be unwrapped');

        // [GIVEN] a body that is not a value-envelope [THEN] it is returned unchanged
        Assert.AreEqual('{"records":[]}', LibraryMasterDataMgt.UnwrapHttpTransportODataValue('{"records":[]}'), 'A non-envelope body should pass through unchanged');

        CleanUp();
    end;

    [ModalPageHandler]
    procedure PrivacyNoticeModalHandler(var PrivacyNoticePage: TestPage "Privacy Notice")
    begin
        // Reached only if the wizard actually opened the notice.
        WizardPrivacyNoticeOpenCount += 1;
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
    procedure CrossEnvIntegrationRecRefCountReportsExistence()
    var
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] The full-synch review existence probe reports records for a non-empty cross-env source table.
        Initialize();
        LibrarySalesLib.CreateCustomer(Customer);
        CreateMinimalCustomerMapping(IntegrationTableMapping);
        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();

        Assert.AreEqual(1, LibraryMasterDataMgt.GetIntegrationRecRefCount(IntegrationTableMapping), 'A non-empty source table should report records to the full-synch review');

        CleanUp();
    end;

    [Test]
    procedure ConnectionDetailsWizardSavesConfiguration()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        PrivacyNotice: Codeunit "Privacy Notice";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        AzureADTenant: Codeunit "Azure AD Tenant";
        ConnectionDetails: TestPage "MDM Connection Details";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] The Connection Details wizard collects the source connection details and saves them (secret to Isolated Storage).
        Initialize();
        // Pre-approve so ticking consent doesn't open the notice dialog in this configuration-focused test.
        PrivacyNotice.SetApprovalState(LibraryMasterDataMgt.PrivacyNoticeId(), "Privacy Notice Approval State"::Agreed);

        ConnectionDetails.OpenEdit();
        // Welcome step: consent is pre-approved above, so Next advances without prompting.
        ConnectionDetails.ActionNext.Invoke();
        // Connection step: provide the source environment and credentials (the URL is derived from the environment name).
        ConnectionDetails.SourceEnvironmentName.SetValue('CONTOSO-PROD');
        ConnectionDetails.SourceCompanyName.SetValue('CRONUS');
        ConnectionDetails.OAuth2ClientId.SetValue('11111111-2222-3333-4444-555555555555');
        ConnectionDetails.OAuth2ClientSecret.SetValue('super-secret');
        ConnectionDetails.ActionNext.Invoke(); // -> Test Connection step
        ConnectionDetails.ActionNext.Invoke(); // -> Finish step (optional test skipped)
        ConnectionDetails.ActionFinish.Invoke();

        // [THEN] the setup holds the connection and a stored client secret
        MasterDataManagementSetup.Get();
        Assert.AreEqual('CONTOSO-PROD', MasterDataManagementSetup."Source Environment Name", 'Source environment not saved');
        // The URL is constructed from the current tenant, ring host, and source environment name.
        Assert.IsTrue(
            StrPos(MasterDataManagementSetup."Source Environment URL", '/v2.0/' + AzureADTenant.GetAadTenantId() + '/CONTOSO-PROD') > 0,
            'Source URL should embed the tenant id and source environment name');
        Assert.IsTrue(
            StrPos(LowerCase(MasterDataManagementSetup."Source Environment URL"), 'https://api.businesscentral.dynamics') = 1,
            'Source URL should target the Business Central API host');
        Assert.AreEqual('CRONUS', MasterDataManagementSetup."Source Company Name", 'Source company not saved');
        Assert.AreEqual('11111111-2222-3333-4444-555555555555', MasterDataManagementSetup."Source OAuth Client Id", 'Source client id not saved');
        Assert.IsFalse(IsNullGuid(MasterDataManagementSetup."Source Client Secret Key"), 'Client secret should be stored');

        // Restore privacy state so this configuration test doesn't leak consent into later privacy-notice scenarios.
        LibraryMasterDataMgt.PrivacyNoticeResetApproval();
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ClearCrossEnvSetupRevertsToSameEnvironment()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        SetupPage: TestPage "Master Data Management Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Clear Cross-Environment Setup removes the source environment, company, client id, and the stored
        //            secret, reverting the setup to same-environment synchronization.
        Initialize();
        // [GIVEN] a configured cross-environment connection with a stored secret
        MasterDataManagementSetup.Get();
        MasterDataManagementSetup.Validate("Source Environment Name", 'CONTOSO-PROD');
        MasterDataManagementSetup."Source Environment URL" := 'https://api.businesscentral.dynamics.com/v2.0/contoso-prod';
        MasterDataManagementSetup."Source Company Name" := 'CRONUS';
        MasterDataManagementSetup."Source OAuth Client Id" := '11111111-2222-3333-4444-555555555555';
        MasterDataManagementSetup."Source Client Secret Key" := CreateGuid(); // simulate a stored secret key
        MasterDataManagementSetup.Modify(true);
        Assert.AreNotEqual('', MasterDataManagementSetup."Source Environment Name", 'Precondition: setup should be cross-environment');

        // [WHEN] the user runs Clear Cross-Environment Setup and confirms
        SetupPage.OpenEdit();
        SetupPage.ClearCrossEnvSetup.Invoke();
        SetupPage.Close();

        // [THEN] every cross-environment field and the stored secret are cleared
        MasterDataManagementSetup.Get();
        Assert.AreEqual('', MasterDataManagementSetup."Source Environment Name", 'Source environment should be cleared');
        Assert.AreEqual('', MasterDataManagementSetup."Source Environment URL", 'Source URL should be cleared');
        Assert.AreEqual('', MasterDataManagementSetup."Source Company Name", 'Source company should be cleared');
        Assert.AreEqual('', MasterDataManagementSetup."Source OAuth Client Id", 'Source client id should be cleared');
        Assert.IsTrue(IsNullGuid(MasterDataManagementSetup."Source Client Secret Key"), 'Secret key should be cleared'); // empty Source Environment Name (asserted above) means same-environment again

        CleanUp();
    end;

    [Test]
    procedure ClearCrossEnvSetupDisabledWhileSynchronizationEnabled()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        SetupPage: TestPage "Master Data Management Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Clear Cross-Environment Setup is disabled while synchronization is enabled, so the user must
        //            disable synchronization before the connection can be cleared.
        Initialize();
        // [GIVEN] a cross-environment setup with synchronization enabled
        MasterDataManagementSetup.Get();
        MasterDataManagementSetup.Validate("Source Environment Name", 'CONTOSO-PROD');
        MasterDataManagementSetup."Is Enabled" := true; // set directly to skip the enable side effects; the action's Enabled binding is what we assert
        MasterDataManagementSetup.Modify(false);

        // [THEN] the Clear Cross-Environment Setup action is disabled on the setup page
        SetupPage.OpenEdit();
        Assert.IsFalse(SetupPage.ClearCrossEnvSetup.Enabled(), 'Clear action should be disabled while synchronization is enabled');
        SetupPage.Close();

        // reset the enabled flag so it does not leak into later tests
        MasterDataManagementSetup.Get();
        MasterDataManagementSetup."Is Enabled" := false;
        MasterDataManagementSetup.Modify(false);
        CleanUp();
    end;

    [Test]
    procedure CrossEnvGetByFilterReturnsRecordsPastTheWatermark()
    var
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        FilterSourceRef: RecordRef;
        ModifiedSetSourceRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] GetByFilter returns the whole filtered set (used by coupling/uncoupling), ignoring the mapping's
        //            watermark, unlike GetModifiedSet which only returns changes after the watermark.
        Initialize();
        LibrarySalesLib.CreateCustomer(Customer);
        CreateMinimalCustomerMapping(IntegrationTableMapping);
        // [GIVEN] a watermark far in the future, so the seeded customer is not "modified since"
        IntegrationTableMapping."Synch. Modified On Filter" := CreateDateTime(DMY2Date(1, 1, 2099), 0T);
        IntegrationTableMapping.Modify();

        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();

        // [THEN] the watermark-based read excludes it, but the full filtered read includes it
        Assert.IsFalse(
            LibraryMasterDataMgt.DataSourceGetModifiedSet(IntegrationTableMapping, '', ModifiedSetSourceRef) and ContainsSystemId(ModifiedSetSourceRef, Customer.SystemId),
            'GetModifiedSet should not return records at or before the watermark');
        Assert.IsTrue(LibraryMasterDataMgt.DataSourceGetByFilter(IntegrationTableMapping, '', FilterSourceRef), 'GetByFilter should return records');
        Assert.IsTrue(ContainsSystemId(FilterSourceRef, Customer.SystemId), 'GetByFilter should return the seeded customer regardless of the watermark');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvErrorsWhenSourceLacksRecordsCapability()
    var
        Customer: Record Customer;
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] The subsidiary negotiates capabilities first and fails clearly if the source doesn't advertise 'records'.
        Initialize();
        LibrarySalesLib.CreateCustomer(Customer);
        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();
        InProcessTransport.SetCannedCapabilities('{"version":1,"features":["lastModifiedPerTable"]}');

        asserterror LibraryMasterDataMgt.DataSourceGetBySystemId(Database::Customer, Customer.SystemId, SourceRecordRef);
        Assert.ExpectedError('does not support the required');

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
        PerRunCounts: List of [Integer];
        Watermark: DateTime;
        Cursor: Text;
        EndCursor: Text;
        PreviousCursor: Text;
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
            PreviousCursor := Cursor;
            LibraryMasterDataMgt.DataSourceGetModifiedBatch(IntegrationTableMapping, '', Cursor, 1, SourceRecordRef, EndCursor, HasMore);
            // Each resumed run must advance from the cursor it was given - never restart from the start or stall.
            Assert.AreNotEqual(PreviousCursor, EndCursor, 'Each resumed run must advance the cursor');
            PerRunCounts.Add(SourceRecordRef.Count());
            CollectSystemIds(SourceRecordRef, CollectedSystemIds);
            Cursor := EndCursor;
            Runs += 1;
        until not HasMore;

        // [THEN] the set drained in a stable 2 + 2 + 1 sequence across exactly three resumed runs
        Assert.AreEqual(3, Runs, 'A 5-record set at 2/page and 1 page/run must take exactly three runs');
        Assert.AreEqual(2, PerRunCounts.Get(1), 'First run should return a full page of two records');
        Assert.AreEqual(2, PerRunCounts.Get(2), 'Second run should return a full page of two records');
        Assert.AreEqual(1, PerRunCounts.Get(3), 'Final run should return the remaining single record');
        // [THEN] every seeded record was returned exactly once (no overlap, no gaps)
        Assert.AreEqual(5, CollectedSystemIds.Count(), 'Every seeded record should be returned exactly once across runs');
        foreach SeededSystemId in SeededSystemIds do
            Assert.IsTrue(CollectedSystemIds.Contains(SeededSystemId), 'Every seeded record should be covered by the resumed batches');

        PagingConfig.Deactivate();
        CleanUp();
    end;

    [Test]
    procedure CrossEnvBlobFieldRoundTrips()
    var
        TestTableA: Record "MDM Test Table A";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        TempBlob: Codeunit "Temp Blob";
        SourceRecordRef: RecordRef;
        BlobField: FieldRef;
        BlobInStream: InStream;
        BlobText: Text;
    begin
        // [FEATURE] [AI test 0.4] [Master Data Management] [Cross-Environment]
        // [SCENARIO] A Blob field is projected inline (base64) and materialized back onto the temp source record.
        Initialize();
        CreateTestTableAWithBlob(TestTableA, 'the quick brown fox');

        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();

        Assert.IsTrue(LibraryMasterDataMgt.DataSourceGetBySystemId(Database::"MDM Test Table A", TestTableA.SystemId, SourceRecordRef), 'Record should be materialized');
        BlobField := SourceRecordRef.Field(TestTableA.FieldNo("Test Blob"));
        TempBlob.FromFieldRef(BlobField);
        Assert.IsTrue(TempBlob.HasValue(), 'Blob should round-trip onto the materialized record');
        TempBlob.CreateInStream(BlobInStream, TextEncoding::UTF8);
        BlobInStream.ReadText(BlobText);
        Assert.AreEqual('the quick brown fox', BlobText, 'Blob content should round-trip through the wire');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvOversizeBlobIsSkipped()
    var
        TestTableA: Record "MDM Test Table A";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        TempBlob: Codeunit "Temp Blob";
        SourceRecordRef: RecordRef;
        BlobField: FieldRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A Blob over the 512 KB inline cap is skipped: the record materializes without the blob.
        Initialize();
        CreateTestTableAWithBlob(TestTableA, PadStr('', 600000, 'A')); // > 512 KB raw

        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();

        Assert.IsTrue(LibraryMasterDataMgt.DataSourceGetBySystemId(Database::"MDM Test Table A", TestTableA.SystemId, SourceRecordRef), 'Record should still materialize');
        BlobField := SourceRecordRef.Field(TestTableA.FieldNo("Test Blob"));
        TempBlob.FromFieldRef(BlobField);
        Assert.IsFalse(TempBlob.HasValue(), 'Over-cap blob must be skipped, not synchronized');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvMediaFieldIsCachedForApply()
    var
        TestTableA: Record "MDM Test Table A";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A Media field's bytes are cached (keyed by SystemId+fieldNo) for the transfer-time apply.
        Initialize();
        CreateTestTableAWithImage(TestTableA, 'small picture bytes');

        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();

        Assert.IsTrue(LibraryMasterDataMgt.DataSourceGetBySystemId(Database::"MDM Test Table A", TestTableA.SystemId, SourceRecordRef), 'Record should be materialized');
        Assert.IsTrue(
            LibraryMasterDataMgt.InlineMediaCacheContains(TestTableA.SystemId, TestTableA.FieldNo("Test Image")),
            'Inline media bytes should be cached for the transfer-time apply');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvEmptyMediaFieldMarksDestinationCleared()
    var
        TestTableA: Record "MDM Test Table A";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment]
        // [SCENARIO] A source record whose Media field is empty is marked cleared so the destination picture is
        // removed during transfer (mirroring a source deletion), instead of leaving a stale image behind.
        Initialize();
        Clear(TestTableA);
        TestTableA."Primary Key" := CopyStr('M' + Format(LibraryRandomInt()), 1, MaxStrLen(TestTableA."Primary Key"));
        TestTableA.Insert(); // no Test Image: the source serializes the media field as empty

        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();

        Assert.IsTrue(LibraryMasterDataMgt.DataSourceGetBySystemId(Database::"MDM Test Table A", TestTableA.SystemId, SourceRecordRef), 'Record should be materialized');
        Assert.IsTrue(
            LibraryMasterDataMgt.InlineMediaIsCleared(TestTableA.SystemId, TestTableA.FieldNo("Test Image")),
            'An empty source media field must be marked cleared so the destination picture is removed');
        Assert.IsFalse(
            LibraryMasterDataMgt.InlineMediaCacheContains(TestTableA.SystemId, TestTableA.FieldNo("Test Image")),
            'An empty source media field must not cache any bytes');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvOversizeMediaIsSkipped()
    var
        TestTableA: Record "MDM Test Table A";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A Media over the 512 KB cap is skipped: no bytes are cached (telemetry-only warning).
        Initialize();
        CreateTestTableAWithImage(TestTableA, PadStr('', 600000, 'A')); // > 512 KB raw

        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();

        Assert.IsTrue(LibraryMasterDataMgt.DataSourceGetBySystemId(Database::"MDM Test Table A", TestTableA.SystemId, SourceRecordRef), 'Record should still materialize');
        Assert.IsFalse(
            LibraryMasterDataMgt.InlineMediaCacheContains(TestTableA.SystemId, TestTableA.FieldNo("Test Image")),
            'Over-cap media must not be cached (skipped, telemetry only)');

        CleanUp();
    end;

    [Test]
    procedure CrossEnvPageStopsAtInlineByteBudget()
    var
        TestTableA: Record "MDM Test Table A";
        IntegrationTableMapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        PagingConfig: Codeunit "MDM Test Paging Config";
        SourceRecordRef: RecordRef;
        Watermark: DateTime;
        EndCursor: Text;
        HasMore: Boolean;
        Index: Integer;
        Count: Integer;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A page stops at the inline-byte budget: media-heavy records page out even under the record count cap.
        Initialize();

        // [GIVEN] three media records created after a captured watermark, and a byte budget so small any one media fills it
        Watermark := CurrentDateTime();
        Sleep(100);
        for Index := 1 to 3 do
            CreateTestTableAWithImage(TestTableA, 'picture bytes');
        CreateTestTableAMapping(IntegrationTableMapping);
        IntegrationTableMapping."Synch. Modified On Filter" := Watermark;
        IntegrationTableMapping.Modify();

        LibraryMasterDataMgt.SetSourceEnvironmentName('PROD');
        InProcessTransport.Activate();
        PagingConfig.ActivateInlineBytes(1); // 1-byte budget: the first inlined media ends the page

        // [WHEN] a single page is fetched
        LibraryMasterDataMgt.DataSourceGetModifiedBatch(IntegrationTableMapping, '', '', 1, SourceRecordRef, EndCursor, HasMore);
        if SourceRecordRef.FindSet() then
            repeat
                Count += 1;
            until SourceRecordRef.Next() = 0;

        // [THEN] the byte budget capped the page to one record, with more remaining
        Assert.AreEqual(1, Count, 'The inline-byte budget should stop the page after the first media record');
        Assert.IsTrue(HasMore, 'More records should remain past the byte-budget cap');

        PagingConfig.Deactivate();
        CleanUp();
    end;

    local procedure CreateTestTableAMapping(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := CopyStr('MDMXENV' + Format(LibraryRandomInt()), 1, MaxStrLen(IntegrationTableMapping.Name));
        IntegrationTableMapping.Type := IntegrationTableMapping.Type::"Master Data Management";
        IntegrationTableMapping."Table ID" := Database::"MDM Test Table A";
        IntegrationTableMapping."Integration Table ID" := Database::"MDM Test Table A";
        IntegrationTableMapping."Integration Table UID Fld. No." := 2000000000; // SystemId
        IntegrationTableMapping."Int. Tbl. Modified On Fld. No." := 2000000003; // SystemModifiedAt
        IntegrationTableMapping."Delete After Synchronization" := false;
        IntegrationTableMapping.Insert();
        // map the Media field (5) so the batch requests it and the page carries inline bytes
        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationFieldMapping."Field No." := 5;
        IntegrationFieldMapping."Integration Table Field No." := 5;
        IntegrationFieldMapping.Insert(true);
    end;

    local procedure CreateTestTableAWithBlob(var TestTableA: Record "MDM Test Table A"; Content: Text)
    var
        BlobOutStream: OutStream;
    begin
        Clear(TestTableA);
        TestTableA."Primary Key" := CopyStr('B' + Format(LibraryRandomInt()), 1, MaxStrLen(TestTableA."Primary Key"));
        TestTableA."Test Blob".CreateOutStream(BlobOutStream, TextEncoding::UTF8);
        BlobOutStream.WriteText(Content);
        TestTableA.Insert();
    end;

    local procedure CreateTestTableAWithImage(var TestTableA: Record "MDM Test Table A"; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        MediaInStream: InStream;
        MediaOutStream: OutStream;
    begin
        Clear(TestTableA);
        TestTableA."Primary Key" := CopyStr('M' + Format(LibraryRandomInt()), 1, MaxStrLen(TestTableA."Primary Key"));
        TestTableA.Insert();
        TempBlob.CreateOutStream(MediaOutStream, TextEncoding::UTF8);
        MediaOutStream.WriteText(Content);
        TempBlob.CreateInStream(MediaInStream, TextEncoding::UTF8);
        TestTableA."Test Image".ImportStream(MediaInStream, 'pic.bin', 'application/octet-stream');
        TestTableA.Modify();
    end;

    local procedure Initialize()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        PagingConfig: Codeunit "MDM Test Paging Config";
    begin
        InProcessTransport.Deactivate();
        PagingConfig.Deactivate(); // a paging test that failed before its CleanUp must not leak its forced page cap into later tests
        LibraryMasterDataMgt.ApproveCrossEnvPrivacyNotice(); // the source API is consent-gated; approve for the gated paths
        // SetSourceEnvironmentName validates the setup, which schedules the detector job and commits, so a mapping
        // created earlier in a test survives AutoRollback; clear leftovers to keep tests independent.
        DeleteTestArtifacts();
        if not MasterDataManagementSetup.Get() then begin
            MasterDataManagementSetup.Init();
            MasterDataManagementSetup.Insert();
        end;
        MasterDataManagementSetup."Source Environment Name" := '';
        MasterDataManagementSetup.Modify(false);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
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
        DeleteTestArtifacts();
    end;

    local procedure DeleteTestArtifacts()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TestTableA: Record "MDM Test Table A";
    begin
        IntegrationFieldMapping.SetFilter("Integration Table Mapping Name", 'MDMXENV*');
        IntegrationFieldMapping.DeleteAll();
        IntegrationTableMapping.SetFilter(Name, 'MDMXENV*');
        IntegrationTableMapping.DeleteAll();
        TestTableA.DeleteAll(); // deterministic LibraryRandom keys collide across tests; the setup commit survives rollback
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
        // Record every occurrence (no de-dup) so a record returned on two pages makes the count exceed the seeded set.
        if SourceRecordRef.FindSet() then
            repeat
                SystemIdValue := SourceRecordRef.Field(SourceRecordRef.SystemIdNo()).Value();
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
