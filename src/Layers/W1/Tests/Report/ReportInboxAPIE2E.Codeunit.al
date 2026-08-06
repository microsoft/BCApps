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

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxItems()
    var
        ReportInbox: Record "Report Inbox";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns report inbox entries for the current user
        Initialize();
        CreateReportInboxEntry(ReportInbox, UserId());

        // [GIVEN] reportInboxItems URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', 690, ReportInboxItemsTxt);

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
        OtherUserId := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ReportInbox."User ID"));
        CreateReportInboxEntry(ReportInbox, OtherUserId);

        // [GIVEN] reportInboxItems URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', 690, ReportInboxItemsTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response does not contain the other user's entry
        Assert.IsTrue(StrPos(ResponseText, OtherUserId) = 0, 'Response contains another user''s entry');
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
        TargetURL := LibraryGraphMgt.CreateTargetURL('', 690, ReportInboxItemsTxt);

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
        TargetURL := LibraryGraphMgt.CreateTargetURL('', 691, ReportInboxContentsTxt);

        // [WHEN] User sends a GET request without a key
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 400);

        // [THEN] An error is raised because a key is required
        Assert.ExpectedError('systemId');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxContentByKey()
    var
        ReportInbox: Record "Report Inbox";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET with a valid key returns the report inbox content
        Initialize();
        CreateReportInboxEntry(ReportInbox, UserId());

        // [GIVEN] reportInboxContents URI with a specific systemId
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ReportInbox.SystemId), 691, ReportInboxContentsTxt);

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
        TargetURL := LibraryGraphMgt.CreateTargetURL('', 691, ReportInboxContentsTxt);

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
        TargetURL := LibraryGraphMgt.CreateTargetURL('', 692, ReportInboxFilesTxt);

        // [WHEN] User sends a GET request without a key
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 400);

        // [THEN] An error is raised because a key is required
        Assert.ExpectedError('systemId');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxFileByKey()
    var
        ReportInbox: Record "Report Inbox";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET with a valid key returns the report inbox file
        Initialize();
        CreateReportInboxEntry(ReportInbox, UserId());

        // [GIVEN] reportInboxFiles URI with a specific systemId
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ReportInbox.SystemId), 692, ReportInboxFilesTxt);

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
        TargetURL := LibraryGraphMgt.CreateTargetURL('', 692, ReportInboxFilesTxt);

        // [WHEN] User sends a POST request
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '{}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxCompanies()
    var
        ReportInbox: Record "Report Inbox";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns companies with report inbox entries for the current user
        Initialize();
        CreateReportInboxEntry(ReportInbox, UserId());

        // [GIVEN] reportInboxCompanies URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', 694, ReportInboxCompaniesTxt);

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
        TargetURL := LibraryGraphMgt.CreateTargetURL('', 694, ReportInboxCompaniesTxt);

        // [WHEN] User sends a POST request
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '{}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    local procedure Initialize()
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.DeleteAll();
        Commit();
    end;

    local procedure CreateReportInboxEntry(var ReportInbox: Record "Report Inbox"; UserID: Text)
    begin
        ReportInbox.Init();
        ReportInbox."User ID" := CopyStr(UserID, 1, MaxStrLen(ReportInbox."User ID"));
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Report ID" := Report::"Test Report - Default=Word";
        ReportInbox.Description := 'Test Report';
        ReportInbox.Insert(true);
        Commit();
    end;
}
