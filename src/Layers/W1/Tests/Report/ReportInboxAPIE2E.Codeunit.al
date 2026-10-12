// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Environment;
using System.Security.AccessControl;

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
        SeededEntryTxt: Label 'Test Report';
        OtherUserEntryTxt: Label 'Entry belonging to another user';
        ProbePrefixTxt: Label 'RIPROBE', Locked = true;
        AllCompaniesFilterTxt: Label '?$filter=includeAllCompanies eq true', Locked = true;
        MarkReadBodyTxt: Label '{"read": true}', Locked = true;
        CannotAddressCompanyErr: Label 'Cannot address company %1', Comment = '%1 = company name';
        ApiCallerValue: Text;
        ApiCallerResolved: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxItems()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns report inbox entries for the current user
        Initialize();
        SeedEntryForApiCaller(SeededEntryTxt);

        // [GIVEN] reportInboxItems URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Items API", ReportInboxItemsTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response contains the seeded entry, not just the shape
        Assert.IsTrue(StrPos(ResponseText, '"entryNo"') > 0, 'Response does not contain entries');
        Assert.IsTrue(StrPos(ResponseText, SeededEntryTxt) > 0, 'Response does not contain the seeded entry description');
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
        SeedEntryForApiCaller(SeededEntryTxt);
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
    procedure TestPatchReportInboxItemMarksRead()
    var
        ReportInbox: Record "Report Inbox";
        TargetURL: Text;
        ResponseText: Text;
        EntryId: Text;
    begin
        // [SCENARIO] PATCH marks an entry as read for the current user
        Initialize();
        EntryId := SeedEntryForApiCallerAndGetId(SeededEntryTxt);

        // [GIVEN] reportInboxItems URI for that entry
        TargetURL := LibraryGraphMgt.CreateTargetURL(EntryId, Page::"Report Inbox Items API", ReportInboxItemsTxt);

        // [WHEN] the caller patches read to true
        Commit();
        LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, MarkReadBodyTxt, ResponseText, 200);
        Commit();

        // [THEN] the change is written through to the persisted entry, not just the buffer
        ReportInbox.Reset();
        ReportInbox.SetRange("User ID", CopyStr(ApiCallerUserId(), 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.SetRange(Description, SeededEntryTxt);
        Assert.IsTrue(ReportInbox.FindFirst(), 'The seeded entry could not be found.');
        Assert.IsTrue(ReportInbox.Read, 'The entry was not marked as read.');
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

        // [THEN] An error is raised because a key is required, naming this endpoint
        Assert.ExpectedError('for example reportInboxContents');
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

        // [GIVEN] the systemId of an entry owned by the API caller
        SystemIdFilter := SeedEntryForApiCallerAndGetId(SeededEntryTxt);

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

        // [THEN] An error is raised because a key is required, naming this endpoint
        Assert.ExpectedError('for example reportInboxFiles');
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

        // [GIVEN] the systemId of an entry owned by the API caller
        SystemIdFilter := SeedEntryForApiCallerAndGetId(SeededEntryTxt);

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
        SeedEntryForApiCaller(SeededEntryTxt);

        // [GIVEN] reportInboxCompanies URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Companies API", ReportInboxCompaniesTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response contains company data with counts
        Assert.IsTrue(StrPos(ResponseText, '"companyName"') > 0, 'Response does not contain company name');
        Assert.IsTrue(StrPos(ResponseText, '"entryCount"') > 0, 'Response does not contain entry count');
        Assert.IsTrue(StrPos(ResponseText, '"lastModifiedDateTime"') > 0, 'Response does not contain last modified date time');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxItemsAcrossCompanies()
    var
        OtherCompany: Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] With the wider scope, the listing entity returns entries from other companies
        Initialize();
        OtherCompany := OtherCompanyName();
        SeedEntryForApiCaller(SeededEntryTxt);
        SeedEntryForApiCallerIn(OtherCompany, SeededEntryTxt);

        // [GIVEN] reportInboxItems URI asking for every company
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Items API", ReportInboxItemsTxt) + AllCompaniesFilterTxt;

        // [WHEN] User sends a GET request
        Commit();
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Commit();

        // [THEN] Entries from both the addressed company and the other one are returned
        Assert.IsTrue(
            StrPos(ResponseText, '"' + CompanyName() + '"') > 0,
            'Response does not contain an entry from the addressed company');
        Assert.IsTrue(
            StrPos(ResponseText, '"' + OtherCompany + '"') > 0,
            'Response does not contain an entry from ' + OtherCompany + ' - the wider scope did not reach it');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxFileForEntryInAnotherCompanyIsNotWidenedSilently()
    var
        OtherCompany: Text;
        ListURL: Text;
        ListResponse: Text;
        TargetURL: Text;
        ResponseText: Text;
        ForeignSystemId: Text;
    begin
        // [SCENARIO] reportInboxFiles resolves an id only in the company addressed by the URL unless another company is named
        Initialize();
        OtherCompany := OtherCompanyName();
        SeedEntryForApiCallerIn(OtherCompany, SeededEntryTxt);

        // [GIVEN] a systemId discovered in the other company
        ListURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Items API", ReportInboxItemsTxt) + AllCompaniesFilterTxt;
        Commit();
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ListResponse, ListURL, 200);
        Commit();
        ForeignSystemId := SystemIdForCompany(ListResponse, OtherCompany);
        Assert.AreNotEqual('', ForeignSystemId, 'The wider scope returned no entry from ' + OtherCompany);

        // [WHEN] the caller fetches that entry without naming the other company
        TargetURL := LibraryGraphMgt.CreateTargetURL(ForeignSystemId, Page::"Report Inbox File API", ReportInboxFilesTxt);

        // [THEN] it is not found - the URL company is the boundary
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.ExpectedError('404');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxFileForEntryInAnotherCompanyWhenNamed()
    var
        OtherCompany: Text;
        ListURL: Text;
        ListResponse: Text;
        TargetURL: Text;
        ResponseText: Text;
        ForeignSystemId: Text;
    begin
        // [SCENARIO] Naming the other company explicitly widens reportInboxFiles to resolve the id there
        Initialize();
        OtherCompany := OtherCompanyName();
        SeedEntryForApiCallerIn(OtherCompany, SeededEntryTxt);

        // [GIVEN] a systemId discovered in the other company
        ListURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Items API", ReportInboxItemsTxt) + AllCompaniesFilterTxt;
        Commit();
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ListResponse, ListURL, 200);
        Commit();
        ForeignSystemId := SystemIdForCompany(ListResponse, OtherCompany);
        Assert.AreNotEqual('', ForeignSystemId, 'The wider scope returned no entry from ' + OtherCompany);

        // [WHEN] the caller fetches that entry and names the other company
        TargetURL :=
            LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox File API", ReportInboxFilesTxt) +
            '?$filter=id eq ' + ForeignSystemId + ' and companyName eq ''' + OtherCompany + '''';

        // [THEN] the file is returned
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.IsTrue(StrPos(ResponseText, '"fileName"') > 0, 'Response does not contain file name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetReportInboxContentDoesNotResolveAnotherCompany()
    var
        OtherCompany: Text;
        ListURL: Text;
        ListResponse: Text;
        TargetURL: Text;
        ResponseText: Text;
        ForeignSystemId: Text;
    begin
        // [SCENARIO] reportInboxContents resolves only in the company addressed in the request
        Initialize();
        OtherCompany := OtherCompanyName();
        SeedEntryForApiCallerIn(OtherCompany, SeededEntryTxt);

        // [GIVEN] a systemId discovered in the other company
        ListURL := LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Items API", ReportInboxItemsTxt) + AllCompaniesFilterTxt;
        Commit();
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ListResponse, ListURL, 200);
        Commit();
        ForeignSystemId := SystemIdForCompany(ListResponse, OtherCompany);
        Assert.AreNotEqual('', ForeignSystemId, 'The wider scope returned no entry from ' + OtherCompany);

        // [WHEN] the caller asks for that entry without changing the company in the URL
        TargetURL := LibraryGraphMgt.CreateTargetURL(ForeignSystemId, Page::"Report Inbox Content API", ReportInboxContentsTxt);

        // [THEN] it is not found - the entity resolves in the addressed company only
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.ExpectedError('404');
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
        Company: Record Company;
    begin
        if Company.FindSet() then
            repeat
                DeleteEntriesIn(Company.Name, UserId());
                DeleteEntriesIn(Company.Name, ApiCallerUserId());
            until Company.Next() = 0;
        Commit();
    end;

    local procedure DeleteEntriesIn(CompanyToClear: Text; UserID: Text)
    var
        ReportInbox: Record "Report Inbox";
    begin
        if not ReportInbox.ChangeCompany(CopyStr(CompanyToClear, 1, 30)) then
            exit;
        ReportInbox.SetRange("User ID", CopyStr(UserID, 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.DeleteAll();
    end;

    local procedure DeleteEntriesFor(UserID: Text)
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.Reset();
        ReportInbox.SetRange("User ID", CopyStr(UserID, 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.DeleteAll();
    end;

    local procedure SeedEntryForApiCaller(NewDescription: Text)
    begin
        SeedEntryForApiCallerAndGetId(NewDescription);
    end;

    local procedure SeedEntryForApiCallerAndGetId(NewDescription: Text): Text
    var
        ReportInbox: Record "Report Inbox";
    begin
        Clear(ReportInbox);
        ReportInbox."User ID" := CopyStr(ApiCallerUserId(), 1, MaxStrLen(ReportInbox."User ID"));
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Report ID" := Report::"Test Report - Default=Word";
        ReportInbox.Description := CopyStr(NewDescription, 1, MaxStrLen(ReportInbox.Description));
        ReportInbox.Insert(true);
        Commit();
        exit(LowerCase(DelChr(Format(ReportInbox.SystemId), '=', '{}')));
    end;

    local procedure ApiCallerUserId(): Text
    var
        Candidates: List of [Text];
        ResponseText: Text;
        ProbeTag: Text;
        Marker: Text;
        i: Integer;
        MatchCount: Integer;
    begin
        if ApiCallerResolved then
            exit(ApiCallerValue);

        BuildCandidateList(Candidates);
        ProbeTag := ProbePrefixTxt + DelChr(Format(CreateGuid()), '=', '{}-');

        for i := 1 to Candidates.Count() do
            CreateReportInboxEntry(Candidates.Get(i), ProbeTag + '-' + Format(i));
        Commit();

        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(
            ResponseText,
            LibraryGraphMgt.CreateTargetURL('', Page::"Report Inbox Items API", ReportInboxItemsTxt),
            200);
        Commit();

        for i := 1 to Candidates.Count() do begin
            Marker := '"' + ProbeTag + '-' + Format(i) + '"';
            if StrPos(ResponseText, Marker) > 0 then begin
                ApiCallerValue := Candidates.Get(i);
                ApiCallerResolved := true;
                MatchCount += 1;
            end;
        end;

        for i := 1 to Candidates.Count() do
            DeleteProbeEntries(Candidates.Get(i));
        Commit();

        Assert.AreEqual(
            1, MatchCount,
            'Expected exactly one candidate identity to resolve; a different count means user filtering is off.');
        exit(ApiCallerValue);
    end;

    local procedure BuildCandidateList(var Candidates: List of [Text])
    var
        User: Record User;
    begin
        Candidates.Add(UserId());
        Candidates.Add('NT AUTHORITY\NETWORK SERVICE');
        Candidates.Add('NT AUTHORITY\SYSTEM');
        Candidates.Add('NETWORK SERVICE');
        Candidates.Add('SYSTEM');
        if User.FindSet() then
            repeat
                if not Candidates.Contains(User."User Name") then
                    Candidates.Add(User."User Name");
            until User.Next() = 0;
    end;

    local procedure DeleteProbeEntries(UserID: Text)
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.Reset();
        ReportInbox.SetRange("User ID", CopyStr(UserID, 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.SetFilter(Description, ProbePrefixTxt + '*');
        ReportInbox.DeleteAll();
    end;

    local procedure CreateReportInboxEntry(UserID: Text; NewDescription: Text)
    var
        ReportInbox: Record "Report Inbox";
    begin
        Clear(ReportInbox);
        ReportInbox."User ID" := CopyStr(UserID, 1, MaxStrLen(ReportInbox."User ID"));
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Report ID" := Report::"Test Report - Default=Word";
        ReportInbox.Description := CopyStr(NewDescription, 1, MaxStrLen(ReportInbox.Description));
        ReportInbox.Insert(true);
    end;

    local procedure OtherCompanyName(): Text
    var
        ExistingCompany: Record Company;
    begin
        ExistingCompany.SetFilter(Name, '<>%1', CompanyName());
        if ExistingCompany.FindFirst() then
            exit(ExistingCompany.Name);

        exit(CreateSecondaryCompany());
    end;

    local procedure CreateSecondaryCompany(): Text
    var
        NewCompany: Record Company;
    begin
        NewCompany.LockTable(true);
        NewCompany.Name := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(NewCompany.Name));
        NewCompany.Insert(true);
        Commit();
        exit(NewCompany.Name);
    end;

    local procedure SeedEntryForApiCallerIn(CompanyToSeed: Text; NewDescription: Text)
    var
        ReportInbox: Record "Report Inbox";
    begin
        Clear(ReportInbox);
        if not ReportInbox.ChangeCompany(CopyStr(CompanyToSeed, 1, 30)) then
            Error(CannotAddressCompanyErr, CompanyToSeed);
        ReportInbox."User ID" := CopyStr(ApiCallerUserId(), 1, MaxStrLen(ReportInbox."User ID"));
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Report ID" := Report::"Test Report - Default=Word";
        ReportInbox.Description := CopyStr(NewDescription, 1, MaxStrLen(ReportInbox.Description));
        ReportInbox.Insert(true);
        Commit();
    end;

    local procedure SystemIdForCompany(ResponseText: Text; CompanyToFind: Text): Text
    var
        ResponseObject: JsonObject;
        ValueToken: JsonToken;
        EntryToken: JsonToken;
        FieldToken: JsonToken;
        ValueArray: JsonArray;
        i: Integer;
    begin
        if not ResponseObject.ReadFrom(ResponseText) then
            exit('');
        if not ResponseObject.Get('value', ValueToken) then
            exit('');
        ValueArray := ValueToken.AsArray();
        for i := 0 to ValueArray.Count() - 1 do begin
            ValueArray.Get(i, EntryToken);
            if EntryToken.AsObject().Get('companyName', FieldToken) then
                if FieldToken.AsValue().AsText() = CompanyToFind then
                    if EntryToken.AsObject().Get('id', FieldToken) then
                        exit(FieldToken.AsValue().AsText());
        end;
        exit('');
    end;

}
