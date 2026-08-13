// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.HumanResources.Employee;

codeunit 148339 "Expense Activity Log API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        APITestAuthHelper: Codeunit "Expense API Test Auth Helper";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseActivityLogEntries', Locked = true;
        ExpenseReportsServiceNameTok: Label 'expenseReports', Locked = true;
        ExpenseUsersServiceNameTok: Label 'expenseUsers', Locked = true;
        TestDescriptionPrefixLbl: Label 'ACTIVITY API TEST ', Locked = true;

    [Test]
    procedure ActivityLogEntryIsExposedThroughReadOnlyAPI()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EntryNo: BigInteger;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The read-only activity-log API exposes contract and diagnostic fields.
        // [GIVEN] A Submitted activity entry.
        Initialize();
        CreateTestExpenseUser(ExpenseUser);
        CreateTestExpenseReport(ExpenseReportHeader, ExpenseUser."No.");
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Submitted,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser."No.",
            'Submitted for approval');
        ExpenseActivityLogEntry.Get(EntryNo);
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Source Record System ID", ExpenseReportHeader.SystemId);
        Assert.RecordCount(ExpenseActivityLogEntry, 1);
        Commit();

        // [WHEN] The report-scoped activity-log collection is requested.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId),
            Page::"Expense Reports API",
            ExpenseReportsServiceNameTok,
            ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] The response contains stable identity, event, currency, and comment values.
        Assert.AreNotEqual(
            0,
            StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry.SystemId)))),
            'Response must contain the activity entry ID. Response: ' + ResponseText);
        Assert.AreNotEqual(0, StrPos(ResponseText, '"entrynumber"'), 'Response must contain the internal entry number.');
        Assert.AreNotEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseReportHeader.SystemId)))), 'Response must contain the stable subject ID.');
        Assert.AreNotEqual(0, StrPos(ResponseText, '"actortableid"'), 'Response must identify the actor record table.');
        Assert.AreNotEqual(0, StrPos(ResponseText, '"actorid"'), 'Response must identify the actor record.');
        Assert.AreNotEqual(0, StrPos(ResponseText, '"eventtype":"submitted"'), 'Response must contain the stable submitted enum member name.');
        Assert.AreNotEqual(0, StrPos(ResponseText, '"currencylcy"'), 'Response must identify the LCY used by LCY amount fields.');
        Assert.AreNotEqual(0, StrPos(ResponseText, '"comment":"submitted for approval"'), 'Response must contain the event comment.');
        CompleteTest();
    end;

    [Test]
    procedure ActivityLogAPIRejectsWrites()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EntryNo: BigInteger;
        ResponseText: Text;
        CollectionURL: Text;
        EntryURL: Text;
    begin
        // [SCENARIO] The activity-log API cannot be used to mutate audit entries.
        // [GIVEN] An existing activity entry and its collection and entity URLs.
        Initialize();
        CreateTestExpenseUser(ExpenseUser);
        CreateTestExpenseReport(ExpenseReportHeader, ExpenseUser."No.");
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Created,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser."No.",
            '');
        ExpenseActivityLogEntry.Get(EntryNo);
        Commit();

        CollectionURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId),
            Page::"Expense Reports API",
            ExpenseReportsServiceNameTok,
            ServiceNameTok);
        EntryURL :=
            CollectionURL + '(' +
            LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry.SystemId)) + ')';

        // [WHEN] A POST is attempted.
        // [THEN] The API rejects it with Method Not Allowed.
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(CollectionURL, '{}', ResponseText, 405);
        Assert.ExpectedError('POST request failed. Response code is 405');

        // [WHEN] A PATCH is attempted.
        // [THEN] The API rejects it with Method Not Allowed.
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(EntryURL, '{"comment":"changed"}', ResponseText, 405);
        Assert.ExpectedError('PATCH request failed. Response code is 405');

        // [WHEN] A DELETE is attempted.
        // [THEN] The API rejects it with Method Not Allowed.
        asserterror LibraryGraphMgt.DeleteFromWebServiceAndCheckResponseCode(EntryURL, '', ResponseText, 400);
        Assert.ExpectedError('DELETE request failed. Response code is 400');
        CompleteTest();
    end;

    [Test]
    procedure NonSnapshotActivityDoesNotExposeCurrencies()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EntryNo: BigInteger;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Non-snapshot activity does not imply currencies for empty amount fields.
        // [GIVEN] A Created activity entry.
        Initialize();
        CreateTestExpenseUser(ExpenseUser);
        CreateTestExpenseReport(ExpenseReportHeader, ExpenseUser."No.");
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Created,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser."No.",
            '');
        ExpenseActivityLogEntry.Get(EntryNo);
        Commit();

        // [WHEN] The activity entry is requested through the report scope.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId),
            Page::"Expense Reports API",
            ExpenseReportsServiceNameTok,
            ServiceNameTok);
        TargetURL += '(' + LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry.SystemId)) + ')';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] Both LCY and reimbursement currency fields are blank.
        Assert.AreNotEqual(0, StrPos(ResponseText, '"currencylcy":""'), 'Non-snapshot activity must not expose an LCY currency.');
        Assert.AreNotEqual(0, StrPos(ResponseText, '"reimbursementcurrencycode":""'), 'Non-snapshot activity must not expose a reimbursement currency.');
        CompleteTest();
    end;

    [Test]
    procedure UnscopedActivityAPIHidesEntries()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EntryNo: BigInteger;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The activity API does not expose company-wide history without a document or user scope.
        // [GIVEN] An existing activity entry.
        Initialize();
        CreateTestExpenseUser(ExpenseUser);
        CreateTestExpenseReport(ExpenseReportHeader, ExpenseUser."No.");
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Submitted,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser."No.",
            '');
        ExpenseActivityLogEntry.Get(EntryNo);
        Commit();

        // [WHEN] The root activity collection is requested without scope.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Activity Log API", ServiceNameTok);
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 400);

        // [THEN] The endpoint explains that a source or Expense User scope is required.
        Assert.ExpectedError('Activity log entries must be requested through an expense report, posted expense report, or expense user.');
        CompleteTest();
    end;

    [Test]
    procedure SubmitterHistoryReturnsCompleteTimelinesForSubmittedReports()
    var
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: array[2] of Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: array[3] of Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EntryNo: BigInteger;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Submitter history contains every activity entry on reports submitted by the user.
        // [GIVEN] Two reports submitted by different users, with another user's approval on the first report.
        Initialize();
        CreateTestExpenseUser(ExpenseUser[1]);
        CreateTestExpenseUser(ExpenseUser[2]);
        CreateTestExpenseReport(ExpenseReportHeader[1], ExpenseUser[1]."No.");
        CreateTestExpenseReport(ExpenseReportHeader[2], ExpenseUser[2]."No.");
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader[1],
            Enum::"Expense Activity Event Type"::Submitted,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser[1]."No.",
            '');
        ExpenseActivityLogEntry[1].Get(EntryNo);
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader[1],
            Enum::"Expense Activity Event Type"::Approved,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Approver,
            ExpenseUser[2]."No.",
            '');
        ExpenseActivityLogEntry[2].Get(EntryNo);
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader[2],
            Enum::"Expense Activity Event Type"::Submitted,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser[2]."No.",
            '');
        ExpenseActivityLogEntry[3].Get(EntryNo);
        PostedExpenseReportHeader.Init();
        PostedExpenseReportHeader."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(PostedExpenseReportHeader."No."));
        PostedExpenseReportHeader.Description := ExpenseReportHeader[1].Description;
        PostedExpenseReportHeader.Insert();
        ExpenseActivityLogMgt.ReassignExpenseReportEntriesToPosted(ExpenseReportHeader[1], PostedExpenseReportHeader);
        Commit();

        // [WHEN] User-scoped activity is requested without a history role.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseUser[1].SystemId),
            Page::"Expense Users API",
            ExpenseUsersServiceNameTok,
            ServiceNameTok);
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 400);

        // [THEN] The endpoint explains that the role is required.
        Assert.ExpectedError('The historyActorRole filter must be specified as Submitter or Approver.');

        // [WHEN] Submitter history is requested through the first Expense User.
        TargetURL += '?$filter=historyActorRole eq ''Submitter''';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] Both posted-source entries on the first report are returned, while the other submitter's report is excluded.
        Assert.AreNotEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[1].SystemId)))), 'Submitter history must contain the submitted entry.');
        Assert.AreNotEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[2].SystemId)))), 'Submitter history must contain the approver entry on the same report.');
        Assert.AreEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[3].SystemId)))), 'Submitter history must exclude another submitter''s report.');
        CompleteTest();
    end;

    [Test]
    procedure ApproverHistoryReturnsCompleteTimelinesForActedOnReports()
    var
        ExpenseUser: array[3] of Record "Expense User";
        ExpenseReportHeader: array[2] of Record "Expense Report Header";
        ExpenseActivityLogEntry: array[4] of Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EntryNo: BigInteger;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Approver history contains every activity entry on reports acted on by the approver.
        // [GIVEN] Two submitted reports approved by different Expense Users.
        Initialize();
        CreateTestExpenseUser(ExpenseUser[1]);
        CreateTestExpenseUser(ExpenseUser[2]);
        CreateTestExpenseUser(ExpenseUser[3]);
        CreateTestExpenseReport(ExpenseReportHeader[1], ExpenseUser[1]."No.");
        CreateTestExpenseReport(ExpenseReportHeader[2], ExpenseUser[1]."No.");
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader[1],
            Enum::"Expense Activity Event Type"::Submitted,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser[1]."No.",
            '');
        ExpenseActivityLogEntry[1].Get(EntryNo);
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader[1],
            Enum::"Expense Activity Event Type"::Approved,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Approver,
            ExpenseUser[2]."No.",
            '');
        ExpenseActivityLogEntry[2].Get(EntryNo);
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader[2],
            Enum::"Expense Activity Event Type"::Submitted,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser[1]."No.",
            '');
        ExpenseActivityLogEntry[3].Get(EntryNo);
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader[2],
            Enum::"Expense Activity Event Type"::Approved,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Approver,
            ExpenseUser[3]."No.",
            '');
        ExpenseActivityLogEntry[4].Get(EntryNo);
        Commit();

        // [WHEN] Approver history is requested through the second Expense User.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseUser[2].SystemId),
            Page::"Expense Users API",
            ExpenseUsersServiceNameTok,
            ServiceNameTok);
        TargetURL += '?$filter=historyActorRole eq ''Approver''';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] The complete first-report timeline is returned and the other approver's report is excluded.
        Assert.AreNotEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[1].SystemId)))), 'Approver history must contain the submitter entry on the acted-on report.');
        Assert.AreNotEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[2].SystemId)))), 'Approver history must contain the approver entry.');
        Assert.AreEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[3].SystemId)))), 'Approver history must exclude a report acted on by another approver.');
        Assert.AreEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[4].SystemId)))), 'Approver history must exclude the other approver entry.');
        CompleteTest();
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Activity Log API Test");
        CleanupTestData();
        if IsInitialized then
            exit;

        BindSubscription(APITestAuthHelper);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Activity Log API Test");
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Enable Agent" := true;
        ExpenseAgentSetup.Modify();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Activity Log API Test");
    end;

    local procedure CreateTestExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20])
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUserNo, '', '');
        ExpenseReportHeader.Description :=
            CopyStr(TestDescriptionPrefixLbl + Format(CreateGuid()), 1, MaxStrLen(ExpenseReportHeader.Description));
        ExpenseReportHeader.Modify();
    end;

    local procedure CreateTestExpenseUser(var ExpenseUser: Record "Expense User")
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Name :=
            CopyStr(TestDescriptionPrefixLbl + Format(CreateGuid()), 1, MaxStrLen(ExpenseUser.Name));
        ExpenseUser.Modify();
    end;

    local procedure CompleteTest()
    begin
        CleanupTestData();
        Commit();
    end;

    local procedure CleanupTestData()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        EmployeeNumbers: List of [Code[20]];
        EmployeeNo: Code[20];
    begin
        ExpenseActivityLogEntry.SetFilter("Document Description", TestDescriptionPrefixLbl + '*');
        ExpenseActivityLogEntry.DeleteAll();

        ExpenseReportHeader.SetFilter(Description, TestDescriptionPrefixLbl + '*');
        ExpenseReportHeader.DeleteAll(true);

        PostedExpenseReportHeader.SetFilter(Description, TestDescriptionPrefixLbl + '*');
        PostedExpenseReportHeader.DeleteAll(true);

        ExpenseUser.SetFilter(Name, TestDescriptionPrefixLbl + '*');
        if ExpenseUser.FindSet() then
            repeat
                if ExpenseUser."Employee No." <> '' then
                    EmployeeNumbers.Add(ExpenseUser."Employee No.");
            until ExpenseUser.Next() = 0;
        ExpenseUser.DeleteAll(true);

        foreach EmployeeNo in EmployeeNumbers do
            if Employee.Get(EmployeeNo) then
                Employee.Delete(true);
    end;

}
