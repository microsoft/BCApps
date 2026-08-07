// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 135549 "Report Inbox API E2E"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [API] [Report Inbox]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryUtility: Codeunit "Library - Utility";
        ReportInboxItemsTxt: Label 'reportInboxItems', Locked = true;
        ReportInboxContentsTxt: Label 'reportInboxContents', Locked = true;
        ReportInboxFilesTxt: Label 'reportInboxFiles', Locked = true;
        ReportInboxCompaniesTxt: Label 'reportInboxCompanies', Locked = true;
        SeededEntryTxt: Label 'Test Report', Locked = true;
        OtherUserEntryTxt: Label 'Entry belonging to another user', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxItems()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns report inbox entries for the current user
        Initialize();
        SeedEntryForEveryPossibleCaller(SeededEntryTxt);

        // [GIVEN] reportInboxItems URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Items API", ReportInboxItemsTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response contains the entry
        Assert.IsTrue(StrPos(ResponseText, '"entryNo"') > 0, 'Response does not contain entries');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxItemsFiltersToCurrentUser()
    var
        ReportInbox: Record "Report Inbox";
        TargetURL: Text;
        ResponseText: Text;
        OtherUserId: Text[65];
    begin
        // [SCENARIO] GET does not return entries belonging to other users
        Initialize();
        SeedEntryForEveryPossibleCaller(SeededEntryTxt);
        OtherUserId := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ReportInbox."User ID"));
        CreateReportInboxEntry(OtherUserId, OtherUserEntryTxt);
        Commit();

        // [GIVEN] reportInboxItems URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Items API", ReportInboxItemsTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] The caller sees its own entry, so the exclusion below is not vacuous
        Assert.IsTrue(StrPos(ResponseText, '"entryNo"') > 0, 'Response contains no entries at all');

        // [THEN] Response does not contain the other user's entry
        Assert.IsTrue(StrPos(ResponseText, OtherUserEntryTxt) = 0, 'Response contains another user''s entry');

        DeleteEntriesFor(OtherUserId);
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostReportInboxItemsNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] POST is not allowed for reportInboxItems
        Initialize();

        // [GIVEN] reportInboxItems URI
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Items API", ReportInboxItemsTxt);

        // [WHEN] User sends a POST request
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '{}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxContentRequiresKey()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET without a key returns an error for reportInboxContents
        Initialize();

        // [GIVEN] reportInboxContents URI without a key
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Content API", ReportInboxContentsTxt);

        // [WHEN] User sends a GET request without a key
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 400);

        // [THEN] An error is raised because a key is required
        Assert.ExpectedError('systemId');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxContentByKey()
    var
        TargetURL: Text;
        ResponseText: Text;
        SystemIdFilter: Text;
    begin
        // [SCENARIO] GET with a valid key returns the report inbox content
        Initialize();
        SeedEntryForEveryPossibleCaller(SeededEntryTxt);

        // [GIVEN] the systemId of an entry the API caller can see
        SystemIdFilter := SystemIdVisibleToApiCaller();

        // [GIVEN] reportInboxContents URI with a specific systemId
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            SystemIdFilter, Page::"Report Inbox Content API", ReportInboxContentsTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response contains the entry
        Assert.IsTrue(StrPos(ResponseText, '"fileName"') > 0, 'Response does not contain file name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostReportInboxContentNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] POST is not allowed for reportInboxContents
        Initialize();

        // [GIVEN] reportInboxContents URI
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Content API", ReportInboxContentsTxt);

        // [WHEN] User sends a POST request
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '{}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxFileRequiresKey()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET without a key returns an error for reportInboxFiles
        Initialize();

        // [GIVEN] reportInboxFiles URI without a key
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox File API", ReportInboxFilesTxt);

        // [WHEN] User sends a GET request without a key
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 400);

        // [THEN] An error is raised because a key is required
        Assert.ExpectedError('systemId');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxFileByKey()
    var
        TargetURL: Text;
        ResponseText: Text;
        SystemIdFilter: Text;
    begin
        // [SCENARIO] GET with a valid key returns the report inbox file
        Initialize();
        SeedEntryForEveryPossibleCaller(SeededEntryTxt);

        // [GIVEN] the systemId of an entry the API caller can see
        SystemIdFilter := SystemIdVisibleToApiCaller();

        // [GIVEN] reportInboxFiles URI with a specific systemId
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            SystemIdFilter, Page::"Report Inbox File API", ReportInboxFilesTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response contains the file metadata
        Assert.IsTrue(StrPos(ResponseText, '"fileName"') > 0, 'Response does not contain file name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostReportInboxFileNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] POST is not allowed for reportInboxFiles
        Initialize();

        // [GIVEN] reportInboxFiles URI
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox File API", ReportInboxFilesTxt);

        // [WHEN] User sends a POST request
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '{}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxCompanies()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns companies with report inbox entries for the current user
        Initialize();
        SeedEntryForEveryPossibleCaller(SeededEntryTxt);

        // [GIVEN] reportInboxCompanies URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Companies API", ReportInboxCompaniesTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response contains company data with counts
        Assert.IsTrue(StrPos(ResponseText, '"companyName"') > 0, 'Response does not contain company name');
        Assert.IsTrue(StrPos(ResponseText, '"entryCount"') > 0, 'Response does not contain entry count');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostReportInboxCompaniesNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] POST is not allowed for reportInboxCompanies
        Initialize();

        // [GIVEN] reportInboxCompanies URI
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Companies API", ReportInboxCompaniesTxt);

        // [WHEN] User sends a POST request
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '{}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    local procedure Initialize()
    var
        User: Record User;
    begin
        DeleteEntriesFor(UserId());
        if User.FindSet() then
            repeat
                DeleteEntriesFor(User."User Name");
            until User.Next() = 0;
        Commit();
    end;

    local procedure DeleteEntriesFor(UserID: Text)
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.Reset();
        ReportInbox.SetRange("User ID", CopyStr(UserID, 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.DeleteAll();
    end;

    /// <summary>
    /// Seeds one report inbox entry per known user.
    /// The API request is issued over HTTP and is therefore a separate session that need not
    /// authenticate as the test session. "Http Web Request Mgt." sends the request with
    /// UseDefaultCredentials, so under Windows authentication it arrives as the NST service
    /// account rather than as UserId(). Pages 690/691/694 filter on UserId(), so an entry
    /// seeded only for the test session is invisible to the API. Seeding one entry per user
    /// guarantees the caller sees exactly one entry - its own - whichever credential type the
    /// server is configured for, without hardcoding a service account name.
    /// </summary>
    local procedure SeedEntryForEveryPossibleCaller(NewDescription: Text)
    var
        User: Record User;
    begin
        CreateReportInboxEntry(UserId(), NewDescription);
        if User.FindSet() then
            repeat
                if User."User Name" <> UserId() then
                    CreateReportInboxEntry(User."User Name", NewDescription);
            until User.Next() = 0;
        Commit();
    end;

    local procedure CreateReportInboxEntry(UserID: Text; NewDescription: Text)
    var
        ReportInbox: Record "Report Inbox";
    begin
        // Clear() rather than Init(): Init() preserves primary key fields, so a repeated call
        // would reuse the AutoIncrement "Entry No." from the previous insert and collide.
        Clear(ReportInbox);
        ReportInbox."User ID" := CopyStr(UserID, 1, MaxStrLen(ReportInbox."User ID"));
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Report ID" := Report::"Test Report - Default=Word";
        ReportInbox.Description := CopyStr(NewDescription, 1, MaxStrLen(ReportInbox.Description));
        ReportInbox.Insert(true);
    end;

    /// <summary>
    /// Reads the systemId of the first entry the API caller can actually see.
    /// Addressing an entry by key has to use a key that belongs to the API session, which is
    /// why the key is discovered from the collection response rather than from the record the
    /// test inserted.
    /// </summary>
    local procedure SystemIdVisibleToApiCaller(): Text
    var
        ListURL: Text;
        ListResponse: Text;
    begin
        ListURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Items API", ReportInboxItemsTxt);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ListResponse, ListURL, 200);
        exit(FirstSystemIdFromResponse(ListResponse));
    end;

    local procedure FirstSystemIdFromResponse(ResponseText: Text): Text
    var
        ResponseObject: JsonObject;
        ValueToken: JsonToken;
        EntryToken: JsonToken;
        SystemIdToken: JsonToken;
        ValueArray: JsonArray;
    begin
        Assert.IsTrue(ResponseObject.ReadFrom(ResponseText), 'The API response is not valid JSON.');
        Assert.IsTrue(ResponseObject.Get('value', ValueToken), 'The API response has no value array.');
        ValueArray := ValueToken.AsArray();
        Assert.IsTrue(ValueArray.Count() > 0, 'The API returned no entries, so there is no key to address.');
        ValueArray.Get(0, EntryToken);
        Assert.IsTrue(EntryToken.AsObject().Get('systemId', SystemIdToken), 'The entry has no systemId.');
        exit(SystemIdToken.AsValue().AsText());
    end;
}
