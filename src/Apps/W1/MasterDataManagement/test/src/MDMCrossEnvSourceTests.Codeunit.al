#pragma warning disable AA0247
codeunit 139931 "MDM Cross-Env Source Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        TableNotAvailableMsg: Label 'Table %1 should be available through the source API', Locked = true, Comment = '%1 = table ID';
        TableNotReadableMsg: Label 'Table %1 should be readable through the source API', Locked = true, Comment = '%1 = table ID';

    [Test]
    procedure GetCapabilitiesReturnsVersionAndFeatures()
    var
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
        Token: JsonToken;
    begin
        // [FEATURE] [AI test 0.4] [Master Data Management] [Cross-Environment]
        // [SCENARIO] GetCapabilities advertises the contract version and supported features.
        Response.ReadFrom(SourceApi.GetCapabilities());

        Response.Get('version', Token);
        Assert.AreEqual(1, Token.AsValue().AsInteger(), 'Unexpected capability version');
        Assert.IsTrue(FeaturesContain(Response, 'records'), 'records feature should be advertised');
        Assert.IsTrue(FeaturesContain(Response, 'lastModifiedPerTable'), 'lastModifiedPerTable feature should be advertised');
    end;

    [Test]
    procedure GetRecordsSignalsConsentRequiredWhenNotApproved()
    var
        Customer: Record Customer;
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
        Token: JsonToken;
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment] [Privacy]
        // [SCENARIO] Without source consent the API returns a structured consentRequired signal (not data, not a raw
        //            error), so the subsidiary can surface a clear message; after approval it serves data.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] this environment has not approved sharing [THEN] the source signals consentRequired and no data
        LibraryMasterDataMgt.PrivacyNoticeResetApproval();
        Response.ReadFrom(SourceApi.GetRecords(Database::Customer, FieldIdsArray(Customer.FieldNo(Name)), SystemIdsSelector(Customer.SystemId), 100, ''));
        Assert.IsTrue(Response.Get('consentRequired', Token) and Token.AsValue().AsBoolean(), 'Source should signal consentRequired when not approved');
        Assert.IsFalse(Response.Contains('records'), 'No records should be served without consent');

        // [WHEN] the environment approves sharing [THEN] the source serves data with no consent signal
        Clear(Response);
        LibraryMasterDataMgt.ApproveCrossEnvPrivacyNotice();
        Response.ReadFrom(SourceApi.GetRecords(Database::Customer, FieldIdsArray(Customer.FieldNo(Name)), SystemIdsSelector(Customer.SystemId), 100, ''));
        Assert.IsFalse(Response.Contains('consentRequired'), 'The consent signal should be absent once approved');
    end;

    [Test]
    procedure GetCapabilitiesSignalsConsentRequiredWhenNotApproved()
    var
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment] [Privacy]
        // [SCENARIO] GetCapabilities reports a missing approval, so the connection check can name it at setup time.
        // [GIVEN] this environment has not approved sharing [THEN] capabilities carry consentRequired
        LibraryMasterDataMgt.PrivacyNoticeResetApproval();
        Response.ReadFrom(SourceApi.GetCapabilities());
        Assert.IsTrue(GetBoolean(Response, 'consentRequired'), 'Capabilities should signal consentRequired when not approved');
        Assert.IsTrue(FeaturesContain(Response, 'records'), 'Features should still be advertised');

        // [WHEN] the environment approves sharing [THEN] the signal is absent
        Clear(Response);
        ApproveSourceConsent();
        Response.ReadFrom(SourceApi.GetCapabilities());
        Assert.IsFalse(Response.Contains('consentRequired'), 'The consent signal should be absent once approved');
    end;

    local procedure ApproveSourceConsent()
    var
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
    begin
        LibraryMasterDataMgt.ApproveCrossEnvPrivacyNotice();
    end;

    [Test]
    procedure SourceReportsTablesTheAppCannotRead()
    var
        Item: Record Item;
        PermissionsMock: Codeunit "Permissions Mock";
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment] [Permissions]
        // [SCENARIO 656413] A table outside the registered app's permission set is reported as readPermission:false instead
        //                   of failing the call, even when the table is empty and no read would raise a permission error.
        ApproveSourceConsent();
        // [GIVEN] an empty Item table, so the answer can't depend on a read failing
        Item.DeleteAll(false);

        // [GIVEN] the session has only the permission set the source admin assigns to the registered app (no Item read)
        // Don't call PermissionsMock.Stop(): the test runner toggles the mock around every test, and stopping it here
        // would leave it inverted for the rest of the session.
        PermissionsMock.Set('MDM Cross-Env Read');
        Assert.IsFalse(Item.ReadPermission(), 'Precondition: the cross-environment permission set should not grant Item read');

        // [WHEN] records are requested from the unreadable table
        Response.ReadFrom(SourceApi.GetRecords(Database::Item, FieldIdsArray(Item.FieldNo(Description)), '{}', 10, ''));

        // [THEN] the source reports the missing read permission and returns no records
        Assert.IsTrue(GetBoolean(Response, 'tableAvailable'), 'The table exists on the source');
        Assert.IsFalse(GetBoolean(Response, 'readPermission'), 'The missing read permission should be reported');
        Assert.AreEqual(0, RecordCount(Response), 'No records should be returned for an unreadable table');
    end;

    [Test]
    procedure ChangeDetectionFlagsOnlyTheTableTheAppCannotRead()
    var
        Item: Record Item;
        PermissionsMock: Codeunit "Permissions Mock";
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
        ItemEntry: JsonObject;
        CustomerEntry: JsonObject;
        TableIds: JsonArray;
        TableIdsText: Text;
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment] [Permissions]
        // [SCENARIO 656413] In a change-detection batch, a table the registered app can't read is flagged and doesn't
        //                   stop the source from answering for the other tables.
        ApproveSourceConsent();
        // [GIVEN] an Item record, so the unreadable table isn't empty
        Item.Init();
        Item."No." := CopyStr(LibraryRandom.RandText(MaxStrLen(Item."No.")), 1, MaxStrLen(Item."No."));
        Item.Insert(false);
        TableIds.Add(Database::Item);
        TableIds.Add(Database::Customer);
        TableIds.WriteTo(TableIdsText);

        // [GIVEN] the session has only the permission set the source admin assigns to the registered app (no Item read)
        PermissionsMock.Set('MDM Cross-Env Read');

        // [WHEN] change detection probes the unreadable table together with a readable one
        Response.ReadFrom(SourceApi.LastModifiedAtPerTable(TableIdsText));

        // [THEN] only the unreadable table is flagged; the readable one is still answered
        GetTableEntry(Response, 0, ItemEntry);
        GetTableEntry(Response, 1, CustomerEntry);
        Assert.IsFalse(GetBoolean(ItemEntry, 'readPermission'), 'The unreadable table should be flagged in the batch');
        Assert.IsFalse(CustomerEntry.Contains('readPermission'), 'A readable table should not be flagged');
        Assert.IsTrue(GetBoolean(CustomerEntry, 'tableAvailable'), 'The readable table should still be answered');
    end;

    [Test]
    procedure GetRecordsBySystemIdReturnsRequestedFields()
    var
        Customer: Record Customer;
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
        RecordObject: JsonObject;
        FieldsObject: JsonObject;
        RecordsArray: JsonArray;
        Token: JsonToken;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] GetRecords with a systemIds selector returns just that record with the requested fields.
        ApproveSourceConsent();
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(Customer.Name));
        Customer.Modify();

        Response.ReadFrom(SourceApi.GetRecords(Database::Customer, FieldIdsArray(Customer.FieldNo(Name)), SystemIdsSelector(Customer.SystemId), 100, ''));

        Response.Get('records', Token);
        RecordsArray := Token.AsArray();
        Assert.AreEqual(1, RecordsArray.Count(), 'Expected exactly the requested record');
        RecordsArray.Get(0, Token);
        RecordObject := Token.AsObject();
        RecordObject.Get('systemId', Token);
        Assert.AreEqual(Format(Customer.SystemId), Token.AsValue().AsText(), 'Wrong systemId returned');
        RecordObject.Get('fields', Token);
        FieldsObject := Token.AsObject();
        FieldsObject.Get(Format(Customer.FieldNo(Name)), Token);
        Assert.AreEqual(Customer.Name, Token.AsValue().AsText(), 'Wrong Name value returned');
    end;

    [Test]
    procedure GetRecordsCursorModePagesWithHasMore()
    var
        Customer: Record Customer;
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Watermark: DateTime;
        Response: JsonObject;
        NextCursor: Text;
        Index: Integer;
        SeededSystemIds: List of [Guid];
        Page1SystemIds: List of [Guid];
        Page2SystemIds: List of [Guid];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Cursor mode pages ascending by (SystemModifiedAt, SystemId) and reports hasMore / nextCursor.
        ApproveSourceConsent();
        Watermark := CurrentDateTime();
        Sleep(50); // ensure the seeded records sort strictly after the watermark
        for Index := 1 to 3 do begin
            Sleep(20); // distinct, strictly increasing SystemModifiedAt so creation order == cursor order
            LibrarySales.CreateCustomer(Customer);
            SeededSystemIds.Add(Customer.SystemId);
        end;

        // [WHEN] the first page of size 2 is requested from the watermark
        Response.ReadFrom(SourceApi.GetRecords(Database::Customer, FieldIdsArray(Customer.FieldNo(Name)), CursorSelector(Watermark), 2, ''));

        // [THEN] two records come back and hasMore is true
        Assert.AreEqual(2, RecordCount(Response), 'First page should hold the page size');
        Assert.IsTrue(GetBoolean(Response, 'hasMore'), 'hasMore should be true while records remain');
        CollectResponseSystemIds(Response, Page1SystemIds);
        NextCursor := NextCursorText(Response);

        // [WHEN] the next page is requested with the returned cursor
        Clear(Response);
        Response.ReadFrom(SourceApi.GetRecords(Database::Customer, FieldIdsArray(Customer.FieldNo(Name)), NextCursor, 2, ''));

        // [THEN] the remaining record comes back and hasMore is false
        Assert.AreEqual(1, RecordCount(Response), 'Second page should hold the remaining record');
        Assert.IsFalse(GetBoolean(Response, 'hasMore'), 'hasMore should be false on the last page');
        CollectResponseSystemIds(Response, Page2SystemIds);

        // [THEN] the pages follow the ascending (SystemModifiedAt, SystemId) order: first two seeded on page one, last on page two
        Assert.AreEqual(2, Page1SystemIds.Count(), 'First page should contain exactly two records');
        Assert.AreEqual(SeededSystemIds.Get(1), Page1SystemIds.Get(1), 'First page, first record should be the earliest-modified customer');
        Assert.AreEqual(SeededSystemIds.Get(2), Page1SystemIds.Get(2), 'First page, second record should be the second-earliest customer');
        Assert.AreEqual(1, Page2SystemIds.Count(), 'Second page should contain exactly one record');
        Assert.AreEqual(SeededSystemIds.Get(3), Page2SystemIds.Get(1), 'Second page should contain the latest-modified customer');
    end;

    [Test]
    procedure LastModifiedAtPerTableReturnsLatestTimestamp()
    var
        Customer: Record Customer;
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
        Entry: JsonObject;
        Tables: JsonArray;
        Token: JsonToken;
        LastModified: DateTime;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] LastModifiedAtPerTable returns each table's latest modification timestamp.
        ApproveSourceConsent();
        LibrarySales.CreateCustomer(Customer);

        Response.ReadFrom(SourceApi.LastModifiedAtPerTable(TableIdsArray(Database::Customer)));

        Response.Get('tables', Token);
        Tables := Token.AsArray();
        Assert.AreEqual(1, Tables.Count(), 'Expected one table entry');
        Tables.Get(0, Token);
        Entry := Token.AsObject();
        Entry.Get('lastModifiedAt', Token);
        Assert.IsTrue(Evaluate(LastModified, Token.AsValue().AsText(), 9), 'lastModifiedAt should be a round-trippable timestamp');
        Assert.IsTrue(LastModified >= Customer.SystemModifiedAt, 'lastModifiedAt should be at least the just-created customer');
    end;

    [Test]
    procedure GetRecordsRejectsTenantMediaInfrastructureTable()
    var
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment] [Security]
        // [SCENARIO] The source API refuses to serve Tenant Media as a top-level table, so a caller holding the media
        // read grant cannot enumerate blobs directly; media stays reachable only inline via a record's media field.
        ApproveSourceConsent();
        Response.ReadFrom(SourceApi.GetRecords(Database::"Tenant Media", FieldIdsArray(1), CursorSelector(CurrentDateTime()), 10, ''));

        // [THEN] the table is reported unavailable and no records are returned
        Assert.IsFalse(GetBoolean(Response, 'tableAvailable'), 'Tenant Media must not be served as a top-level table');
        Assert.AreEqual(0, RecordCount(Response), 'A blocked table must return no records');
    end;

    [Test]
    procedure SourceApiRefusesSystemTables()
    var
        User: Record User;
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
        Entry: JsonObject;
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment] [Security]
        // [SCENARIO 660382] The source API refuses system tables (ID 2000000000 and above) even when the caller can read
        //                   them, because some system tables are readable without an explicit permission.
        ApproveSourceConsent();
        // [GIVEN] a readable system table that has records
        Assert.IsTrue(User.ReadPermission(), 'Precondition: the test session can read the User table');

        // [WHEN] records are requested from the system table
        Response.ReadFrom(SourceApi.GetRecords(Database::User, FieldIdsArray(User.FieldNo("User Name")), '{}', 10, ''));

        // [THEN] the table is reported unavailable and no records are returned
        Assert.IsFalse(GetBoolean(Response, 'tableAvailable'), 'A system table must not be served');
        Assert.AreEqual(0, RecordCount(Response), 'A system table must return no records');

        // [WHEN] change detection probes the system table
        Clear(Response);
        Response.ReadFrom(SourceApi.LastModifiedAtPerTable(TableIdsArray(Database::User)));

        // [THEN] the table is reported unavailable, without a timestamp
        GetTableEntry(Response, 0, Entry);
        Assert.IsFalse(GetBoolean(Entry, 'tableAvailable'), 'A system table must not be probed');
        Assert.IsFalse(Entry.Contains('lastModifiedAt'), 'No timestamp should be returned for a system table');
    end;

    [Test]
    procedure RegisteredAppReadsDefaultTablesOnlyThroughSourceApi()
    var
        Customer: Record Customer;
        PermissionsMock: Codeunit "Permissions Mock";
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
        DefaultTableIds: List of [Integer];
        TableId: Integer;
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment] [Permissions]
        // [SCENARIO 660384] With only the permission set that the source admin assigns to the registered app, the app reads
        //                   every default synchronization table through the source API (indirect read), but can't read
        //                   those tables directly through other endpoints. Also catches drift between the permission set
        //                   and the source API's Permissions property.
        ApproveSourceConsent();
        LibrarySales.CreateCustomer(Customer);
        GetDefaultSynchronizationTableIds(DefaultTableIds);

        // [GIVEN] the session has only the permission set the source admin assigns to the registered app
        // Don't call PermissionsMock.Stop(): the test runner toggles the mock around every test.
        PermissionsMock.Set('MDM Cross-Env Read');

        // [THEN] the default tables aren't readable directly
        Assert.IsFalse(Customer.ReadPermission(), 'The permission set must not grant direct read on Customer');

        // [THEN] every default table is readable through the source API
        foreach TableId in DefaultTableIds do begin
            Clear(Response);
            Response.ReadFrom(SourceApi.GetRecords(TableId, '[]', '{}', 1, ''));
            Assert.IsTrue(GetBoolean(Response, 'tableAvailable'), StrSubstNo(TableNotAvailableMsg, TableId));
            Assert.IsFalse(Response.Contains('readPermission'), StrSubstNo(TableNotReadableMsg, TableId));
        end;

        // [THEN] the source API serves the data, including for change detection
        Clear(Response);
        Response.ReadFrom(SourceApi.GetRecords(Database::Customer, FieldIdsArray(Customer.FieldNo(Name)), SystemIdsSelector(Customer.SystemId), 100, ''));
        Assert.AreEqual(1, RecordCount(Response), 'The customer should be served through the source API');
        Clear(Response);
        Response.ReadFrom(SourceApi.LastModifiedAtPerTable(TableIdsArray(Database::Customer)));
        Assert.IsTrue(TableEntryHasTimestamp(Response, 0), 'Change detection should read Customer through the source API');
    end;

    // The tables synchronized by the default configuration; the permission set and the source API's Permissions
    // property both cover exactly these.
    local procedure GetDefaultSynchronizationTableIds(var TableIds: List of [Integer])
    begin
        TableIds.Add(Database::"Salesperson/Purchaser");
        TableIds.Add(Database::Customer);
        TableIds.Add(Database::Vendor);
        TableIds.Add(Database::Contact);
        TableIds.Add(Database::"Business Relation");
        TableIds.Add(Database::"Contact Business Relation");
        TableIds.Add(Database::"Country/Region");
        TableIds.Add(Database::"Post Code");
        TableIds.Add(Database::Currency);
        TableIds.Add(Database::"Currency Exchange Rate");
        TableIds.Add(Database::"Payment Terms");
        TableIds.Add(Database::"Shipment Method");
        TableIds.Add(Database::"Shipping Agent");
        TableIds.Add(Database::"Sales & Receivables Setup");
        TableIds.Add(Database::"Purchases & Payables Setup");
        TableIds.Add(Database::"Marketing Setup");
        TableIds.Add(Database::"No. Series");
        TableIds.Add(Database::"No. Series Line");
        TableIds.Add(Database::"G/L Account");
        TableIds.Add(Database::Dimension);
        TableIds.Add(Database::"Dimension Value");
        TableIds.Add(Database::"Gen. Business Posting Group");
        TableIds.Add(Database::"Gen. Product Posting Group");
        TableIds.Add(Database::"Customer Posting Group");
        TableIds.Add(Database::"Vendor Posting Group");
        TableIds.Add(Database::"VAT Business Posting Group");
        TableIds.Add(Database::"VAT Product Posting Group");
        TableIds.Add(Database::"VAT Posting Setup");
        TableIds.Add(Database::"Tax Area");
        TableIds.Add(Database::"Tax Group");
        TableIds.Add(Database::"Tax Jurisdiction");
    end;

    local procedure TableEntryHasTimestamp(var Response: JsonObject; Index: Integer): Boolean
    var
        Entry: JsonObject;
        Token: JsonToken;
    begin
        GetTableEntry(Response, Index, Entry);
        if not Entry.Get('lastModifiedAt', Token) then
            exit(false);
        exit(Token.AsValue().AsText() <> '');
    end;

    [Test]
    procedure GetRecordsAppliesRowFilterOnUnprojectedField()
    var
        MatchCustomer: Record Customer;
        OtherCustomer: Record Customer;
        FilterCustomer: Record Customer;
        SourceApi: Codeunit "MDM Cross-Env Source API";
        Response: JsonObject;
        Watermark: DateTime;
        SystemIds: List of [Guid];
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment]
        // [SCENARIO] The source applies the mapping row filter server-side even when it references a field outside the
        // projection (parity with same-env), so only matching records are returned rather than filtered post-hoc.
        ApproveSourceConsent();
        Watermark := CurrentDateTime();
        Sleep(50); // ensure the seeded records sort strictly after the watermark
        LibrarySales.CreateCustomer(MatchCustomer);
        MatchCustomer.Blocked := MatchCustomer.Blocked::All;
        MatchCustomer.Modify();
        LibrarySales.CreateCustomer(OtherCustomer); // Blocked = " ": excluded by the filter

        // [WHEN] records are fetched projecting only Name, with a filter on the (unprojected) Blocked field
        FilterCustomer.SetRange(Blocked, MatchCustomer.Blocked::All);
        Response.ReadFrom(SourceApi.GetRecords(Database::Customer, FieldIdsArray(MatchCustomer.FieldNo(Name)), CursorSelector(Watermark), 100, FilterCustomer.GetView(false)));

        // [THEN] only the customer matching the row filter comes back
        CollectResponseSystemIds(Response, SystemIds);
        Assert.IsTrue(SystemIds.Contains(MatchCustomer.SystemId), 'The customer matching the row filter should be returned');
        Assert.IsFalse(SystemIds.Contains(OtherCustomer.SystemId), 'A customer outside the row filter must be excluded server-side');
    end;

    local procedure FeaturesContain(var Response: JsonObject; Feature: Text): Boolean
    var
        Features: JsonArray;
        FeatureToken: JsonToken;
        Token: JsonToken;
    begin
        Response.Get('features', Token);
        Features := Token.AsArray();
        foreach FeatureToken in Features do
            if FeatureToken.AsValue().AsText() = Feature then
                exit(true);
        exit(false);
    end;

    local procedure RecordCount(var Response: JsonObject): Integer
    var
        Token: JsonToken;
    begin
        Response.Get('records', Token);
        exit(Token.AsArray().Count());
    end;

    local procedure CollectResponseSystemIds(var Response: JsonObject; var SystemIds: List of [Guid])
    var
        RecordsToken: JsonToken;
        RecordToken: JsonToken;
        SystemIdToken: JsonToken;
        SystemIdValue: Guid;
    begin
        // Record every returned systemId (no de-dup) so a repeat across pages is caught by the count assertion.
        Response.Get('records', RecordsToken);
        foreach RecordToken in RecordsToken.AsArray() do
            if RecordToken.AsObject().Get('systemId', SystemIdToken) then
                if Evaluate(SystemIdValue, SystemIdToken.AsValue().AsText()) then
                    SystemIds.Add(SystemIdValue);
    end;

    local procedure GetBoolean(var Response: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        Response.Get(PropertyName, Token);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure GetTableEntry(var Response: JsonObject; Index: Integer; var Entry: JsonObject)
    var
        Token: JsonToken;
    begin
        Response.Get('tables', Token);
        Token.AsArray().Get(Index, Token);
        Entry := Token.AsObject();
    end;

    local procedure NextCursorText(var Response: JsonObject) CursorText: Text
    var
        Token: JsonToken;
    begin
        Response.Get('nextCursor', Token);
        Token.WriteTo(CursorText);
    end;

    local procedure FieldIdsArray(FieldNo: Integer) ResultText: Text
    var
        FieldIds: JsonArray;
    begin
        FieldIds.Add(FieldNo);
        FieldIds.WriteTo(ResultText);
    end;

    local procedure TableIdsArray(TableId: Integer) ResultText: Text
    var
        TableIds: JsonArray;
    begin
        TableIds.Add(TableId);
        TableIds.WriteTo(ResultText);
    end;

    local procedure SystemIdsSelector(SystemId: Guid) ResultText: Text
    var
        Selector: JsonObject;
        SystemIds: JsonArray;
    begin
        SystemIds.Add(Format(SystemId));
        Selector.Add('systemIds', SystemIds);
        Selector.WriteTo(ResultText);
    end;

    local procedure CursorSelector(Watermark: DateTime) ResultText: Text
    var
        Selector: JsonObject;
    begin
        Selector.Add('modifiedAt', Format(Watermark, 0, 9));
        Selector.WriteTo(ResultText);
    end;
}
