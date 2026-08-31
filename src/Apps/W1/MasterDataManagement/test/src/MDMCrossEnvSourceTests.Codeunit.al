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
        PagedSystemIds: List of [Guid];
        SeededSystemId: Guid;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Cursor mode pages ascending by (SystemModifiedAt, SystemId) and reports hasMore / nextCursor.
        Watermark := CurrentDateTime();
        Sleep(50); // ensure the seeded records sort strictly after the watermark
        for Index := 1 to 3 do begin
            LibrarySales.CreateCustomer(Customer);
            SeededSystemIds.Add(Customer.SystemId);
        end;

        // [WHEN] the first page of size 2 is requested from the watermark
        Response.ReadFrom(SourceApi.GetRecords(Database::Customer, FieldIdsArray(Customer.FieldNo(Name)), CursorSelector(Watermark), 2, ''));

        // [THEN] two records come back and hasMore is true
        Assert.AreEqual(2, RecordCount(Response), 'First page should hold the page size');
        Assert.IsTrue(GetBoolean(Response, 'hasMore'), 'hasMore should be true while records remain');
        CollectResponseSystemIds(Response, PagedSystemIds);
        NextCursor := NextCursorText(Response);

        // [WHEN] the next page is requested with the returned cursor
        Clear(Response);
        Response.ReadFrom(SourceApi.GetRecords(Database::Customer, FieldIdsArray(Customer.FieldNo(Name)), NextCursor, 2, ''));

        // [THEN] the remaining record comes back and hasMore is false
        Assert.AreEqual(1, RecordCount(Response), 'Second page should hold the remaining record');
        Assert.IsFalse(GetBoolean(Response, 'hasMore'), 'hasMore should be false on the last page');
        CollectResponseSystemIds(Response, PagedSystemIds);

        // [THEN] the two pages together returned every seeded record exactly once - no repeats, no dropped/reordered records
        Assert.AreEqual(3, PagedSystemIds.Count(), 'Paging should return each record exactly once across the two pages');
        foreach SeededSystemId in SeededSystemIds do
            Assert.IsTrue(PagedSystemIds.Contains(SeededSystemId), 'Every seeded record should appear in the paged results');
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
        Response.ReadFrom(SourceApi.GetRecords(Database::"Tenant Media", FieldIdsArray(1), CursorSelector(CurrentDateTime()), 10, ''));

        // [THEN] the table is reported unavailable and no records are returned
        Assert.IsFalse(GetBoolean(Response, 'tableAvailable'), 'Tenant Media must not be served as a top-level table');
        Assert.AreEqual(0, RecordCount(Response), 'A blocked table must return no records');
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
