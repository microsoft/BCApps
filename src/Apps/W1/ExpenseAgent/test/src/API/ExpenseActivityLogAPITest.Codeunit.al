// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.HumanResources.Employee;

codeunit 148343 "Expense Activity Log API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        LibraryGraphMgt.SetAuthenticationProvider(
            Enum::"API Test Authentication"::"Microsoft Test Environment");
    end;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseActivityLogEntries', Locked = true;
        ExpenseReportsServiceNameTok: Label 'expenseReports', Locked = true;
        ExpenseUsersServiceNameTok: Label 'expenseUsers', Locked = true;
        TestDescriptionPrefixLbl: Label 'ACTIVITY API TEST ', Locked = true;
        SubmitterCommentPropertyTxt: Label '"submitterComment":"%1"', Locked = true;
        MethodNotAllowedResponseErr: Label 'Response code is 405', Locked = true;
        BadRequestResponseErr: Label 'Response code is 400', Locked = true;
        SubmitWithCommentActionTok: Label 'Microsoft.NAV.releaseAndMarkPendingApprovalExpenseReportWithComment', Locked = true;
        ApproveActionTok: Label 'Microsoft.NAV.approvedExpenseReport', Locked = true;
        RejectAndReopenActionTok: Label 'Microsoft.NAV.rejectAndReopenExpenseReport', Locked = true;

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
        CreateTestExpenseReportLine(ExpenseReportHeader, ExpenseUser."No.");
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
        Assert.AreNotEqual(0, StrPos(ResponseText, '"expensecount"'), 'Response must contain the expense count snapshot.');
        Assert.AreNotEqual(0, StrPos(ResponseText, '"attachedreceiptcount"'), 'Response must contain the attached receipt count snapshot.');
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
        EntryURL := LibraryGraphMgt.AppendPathToTargetURL(
            CollectionURL,
            '(' + LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry.SystemId)) + ')');

        // [WHEN] A POST is attempted.
        // [THEN] The API rejects it with Method Not Allowed.
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(CollectionURL, '{}', ResponseText, 405);
        Assert.ExpectedError(MethodNotAllowedResponseErr);

        // [WHEN] A PATCH is attempted.
        // [THEN] The API rejects it with Method Not Allowed.
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(EntryURL, '{"comment":"changed"}', ResponseText, 405);
        Assert.ExpectedError(MethodNotAllowedResponseErr);

        // [WHEN] A DELETE is attempted.
        // [THEN] The API rejects it with Method Not Allowed.
        asserterror LibraryGraphMgt.DeleteFromWebServiceAndCheckResponseCode(EntryURL, '', ResponseText, 400);
        Assert.ExpectedError(BadRequestResponseErr);
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
        TargetURL := LibraryGraphMgt.AppendPathToTargetURL(
            TargetURL, '(' + LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry.SystemId)) + ')');
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
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(
            TargetURL, '$filter=historyActorRole eq ''Submitter''');
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
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(
            TargetURL, '$filter=historyActorRole eq ''Approver''');
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] The complete first-report timeline is returned and the other approver's report is excluded.
        Assert.AreNotEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[1].SystemId)))), 'Approver history must contain the submitter entry on the acted-on report.');
        Assert.AreNotEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[2].SystemId)))), 'Approver history must contain the approver entry.');
        Assert.AreEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[3].SystemId)))), 'Approver history must exclude a report acted on by another approver.');
        Assert.AreEqual(0, StrPos(ResponseText, LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseActivityLogEntry[4].SystemId)))), 'Approver history must exclude the other approver entry.');
        CompleteTest();
    end;

    [Test]
    procedure E2EActivityLogScenario()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        SubjectSystemID: Guid;
        RunToken: Code[8];
    begin
        // [SCENARIO] A complete approval round trip is exposed through active, posted, and user-history APIs.
        Initialize();
        RunToken := CreateRunToken();
        CreateE2ESetup(
            SubmitterExpenseUser, ApproverExpenseUser,
            ExpenseCategory, ExpensePaymentMethod, RunToken);
        CreateE2EReport(
            ExpenseReportHeader, SubmitterExpenseUser,
            ExpenseCategory, ExpensePaymentMethod, RunToken);
        Commit();

        // [WHEN] The report is submitted, rejected/reopened, resubmitted, and approved through API actions.
        InvokeReportAction(
            ExpenseReportHeader.SystemId, SubmitWithCommentActionTok,
            CreateSubmitWithCommentRequestBody(SubmitterExpenseUser."No.", ''));
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        InvokeReportAction(
            ExpenseReportHeader.SystemId, RejectAndReopenActionTok,
            CreateRejectRequestBody(ApproverExpenseUser."No.", 'E2E send back ' + RunToken));
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        InvokeReportAction(
            ExpenseReportHeader.SystemId, SubmitWithCommentActionTok,
            CreateSubmitWithCommentRequestBody(SubmitterExpenseUser."No.", 'E2E submitter response ' + RunToken));
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [THEN] The report API exposes the latest submitter response.
        VerifyReportSubmitterComment(ExpenseReportHeader.SystemId, 'E2E submitter response ' + RunToken);

        InvokeReportAction(
            ExpenseReportHeader.SystemId, ApproveActionTok,
            CreateActorRequestBody('approverExpenseUserNo', ApproverExpenseUser."No."));
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [THEN] The active report timeline contains the approval.
        VerifyReportActivity(
            ExpenseReportHeader.SystemId, Page::"Expense Reports API",
            ExpenseReportsServiceNameTok, Enum::"Expense Activity Event Type"::Approved);

        // [WHEN] The approved report is moved to a posted source fixture.
        SubjectSystemID := ExpenseReportHeader.SystemId;
        MoveReportToPostedSource(ExpenseReportHeader, PostedExpenseReportHeader);
        Commit();

        // [THEN] Posted and user-scoped APIs expose the complete timeline.
        VerifyReportActivity(
            PostedExpenseReportHeader.SystemId, Page::"Posted Expense Reports API",
            'postedExpenseReports', Enum::"Expense Activity Event Type"::Posted);
        VerifyUserHistory(SubmitterExpenseUser.SystemId, 'Submitter', SubjectSystemID);
        VerifyUserHistory(ApproverExpenseUser.SystemId, 'Approver', SubjectSystemID);
        CompleteTest();
    end;

    local procedure CreateE2ESetup(
        var SubmitterExpenseUser: Record "Expense User";
        var ApproverExpenseUser: Record "Expense User";
        var ExpenseCategory: Record "Expense Category";
        var ExpensePaymentMethod: Record "Expense Payment Method";
        RunToken: Code[8]
    )
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        CreateTestExpenseUser(SubmitterExpenseUser);
        SubmitterExpenseUser."User Id For Approvals" :=
            CopyStr('SUBMITTER-' + RunToken, 1, MaxStrLen(SubmitterExpenseUser."User Id For Approvals"));
        SubmitterExpenseUser.Modify();

        CreateTestExpenseUser(ApproverExpenseUser);
        ApproverExpenseUser."Can Approve" := true;
        ApproverExpenseUser."User Id For Approvals" :=
            CopyStr('APPROVER-' + RunToken, 1, MaxStrLen(ApproverExpenseUser."User Id For Approvals"));
        ApproverExpenseUser.Modify();
        LibraryExpense.CreateExpenseApprovalSetup(
            ExpenseApprovalSetup, SubmitterExpenseUser."No.", ApproverExpenseUser."No.");

        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory,
            ExpenseCategory."Reimbursement Type"::"Employee Paid",
            ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Description :=
            CopyStr(TestDescriptionPrefixLbl + RunToken, 1, MaxStrLen(ExpenseCategory.Description));
        ExpenseCategory.Modify();
        LibraryExpense.FindExpensePaymentMethod(
            ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
    end;

    local procedure CreateE2EReport(
        var ExpenseReportHeader: Record "Expense Report Header";
        SubmitterExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        RunToken: Code[8]
    )
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, SubmitterExpenseUser."No.", '', '');
        ExpenseReportHeader.Description :=
            CopyStr(TestDescriptionPrefixLbl + 'E2E ' + RunToken, 1, MaxStrLen(ExpenseReportHeader.Description));
        ExpenseReportHeader.Modify();
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine,
            ExpenseReportHeader,
            SubmitterExpenseUser."No.",
            ExpenseCategory.Code,
            ExpensePaymentMethod.Code,
            true,
            '',
            100);
    end;

    local procedure CreateActorRequestBody(PropertyName: Text; ExpenseUserNo: Code[20]) RequestBody: JsonObject
    begin
        RequestBody.Add(PropertyName, ExpenseUserNo);
    end;

    local procedure CreateRejectRequestBody(ApproverExpenseUserNo: Code[20]; RejectReason: Text) RequestBody: JsonObject
    begin
        RequestBody.Add('approverExpenseUserNo', ApproverExpenseUserNo);
        RequestBody.Add('rejectReason', RejectReason);
    end;

    local procedure CreateSubmitWithCommentRequestBody(SubmitterExpenseUserNo: Code[20]; SubmissionComment: Text) RequestBody: JsonObject
    begin
        RequestBody.Add('submitterExpenseUserNo', SubmitterExpenseUserNo);
        RequestBody.Add('submissionComment', SubmissionComment);
    end;

    local procedure InvokeReportAction(ReportSystemID: Guid; ActionName: Text; RequestBody: JsonObject)
    var
        ResponseText: Text;
        RequestBodyText: Text;
        TargetURL: Text;
    begin
        RequestBody.WriteTo(RequestBodyText);
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ReportSystemID), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ActionName);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBodyText, ResponseText, 200);
    end;

    local procedure MoveReportToPostedSource(
        var ExpenseReportHeader: Record "Expense Report Header";
        var PostedExpenseReportHeader: Record "Posted Expense Report Header"
    )
    var
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
    begin
        PostedExpenseReportHeader.Init();
        PostedExpenseReportHeader.TransferFields(ExpenseReportHeader);
        PostedExpenseReportHeader.Insert();
        ExpenseActivityLogMgt.LogExpenseReportEventByBCUser(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Posted,
            Enum::"Expense Activity Actor Role"::" ",
            '');
        ExpenseActivityLogMgt.ReassignExpenseReportEntriesToPosted(
            ExpenseReportHeader, PostedExpenseReportHeader);
        ExpenseReportHeader.Delete(true);
    end;

    local procedure VerifyReportActivity(
        ReportSystemID: Guid;
        ParentPageID: Integer;
        ParentServiceName: Text;
        ExpectedEventType: Enum "Expense Activity Event Type"
    )
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ReportSystemID), ParentPageID, ParentServiceName, ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.AreNotEqual(
            0,
            StrPos(LowerCase(ResponseText), LowerCase(Format(ExpectedEventType))),
            'The report activity response does not contain the expected event type.');
    end;

    local procedure VerifyReportSubmitterComment(ReportSystemID: Guid; ExpectedComment: Text)
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ReportSystemID), Page::"Expense Reports API", ExpenseReportsServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.AreNotEqual(
            0,
            StrPos(ResponseText, StrSubstNo(SubmitterCommentPropertyTxt, ExpectedComment)),
            'The expense report API response must contain the latest submitter comment.');
    end;

    local procedure VerifyUserHistory(ExpenseUserSystemID: Guid; HistoryRole: Text; SubjectSystemID: Guid)
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseUserSystemID),
            Page::"Expense Users API",
            ExpenseUsersServiceNameTok,
            ServiceNameTok);
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(
            TargetURL, '$filter=historyActorRole eq ''' + HistoryRole + '''');
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.AreNotEqual(
            0,
            StrPos(
                LowerCase(ResponseText),
                LowerCase(LibraryGraphMgt.StripBrackets(Format(SubjectSystemID)))),
            'The user history response does not contain the expected subject.');
    end;

    local procedure CreateRunToken(): Code[8]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 8));
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Activity Log API Test");
        CleanupTestData();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Activity Log API Test");
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Enable Agent" := true;
        ExpenseAgentSetup."Enable Approval Workflow" := false;
        ExpenseAgentSetup."Use Rules" := false;
        ExpenseAgentSetup.Modify();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
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

    local procedure CreateTestExpenseReportLine(ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20])
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory,
            ExpenseCategory."Reimbursement Type"::"Employee Paid",
            ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Description :=
            CopyStr(TestDescriptionPrefixLbl + Format(CreateGuid()), 1, MaxStrLen(ExpenseCategory.Description));
        ExpenseCategory.Modify();
        LibraryExpense.FindExpensePaymentMethod(
            ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine,
            ExpenseReportHeader,
            ExpenseUserNo,
            ExpenseCategory.Code,
            ExpensePaymentMethod.Code,
            true,
            '',
            100);
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
        Expense: Record Expense;
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseSubcategory: Record "Expense Subcategory";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        CategoryCodes: List of [Code[20]];
        EmployeeNumbers: List of [Code[20]];
        ExpenseUserNumbers: List of [Code[20]];
        CategoryCode: Code[20];
        EmployeeNo: Code[20];
        ExpenseUserNo: Code[20];
    begin
        ExpenseUser.SetLoadFields("No.", "Employee No.");
        ExpenseUser.SetFilter(Name, TestDescriptionPrefixLbl + '*');
        if ExpenseUser.FindSet() then
            repeat
                ExpenseUserNumbers.Add(ExpenseUser."No.");
                if (ExpenseUser."Employee No." <> '') and
                   (not EmployeeNumbers.Contains(ExpenseUser."Employee No."))
                then
                    EmployeeNumbers.Add(ExpenseUser."Employee No.");
            until ExpenseUser.Next() = 0;

        ExpenseCategory.SetLoadFields(Code);
        ExpenseCategory.SetFilter(Description, TestDescriptionPrefixLbl + '*');
        if ExpenseCategory.FindSet() then
            repeat
                if not CategoryCodes.Contains(ExpenseCategory.Code) then
                    CategoryCodes.Add(ExpenseCategory.Code);
            until ExpenseCategory.Next() = 0;

        ExpenseActivityLogEntry.SetFilter("Document Description", TestDescriptionPrefixLbl + '*');
        ExpenseActivityLogEntry.DeleteAll();

        ExpenseReportHeader.SetFilter(Description, TestDescriptionPrefixLbl + '*');
        ExpenseReportHeader.DeleteAll(true);

        PostedExpenseReportHeader.SetFilter(Description, TestDescriptionPrefixLbl + '*');
        PostedExpenseReportHeader.DeleteAll(true);

        foreach ExpenseUserNo in ExpenseUserNumbers do begin
            Expense.SetLoadFields("Expense Category", "Expense Report No.");
            Expense.SetRange("Expense User No.", ExpenseUserNo);
            if Expense.FindSet() then
                repeat
                    if (Expense."Expense Category" <> '') and
                       (not CategoryCodes.Contains(Expense."Expense Category"))
                    then
                        CategoryCodes.Add(Expense."Expense Category");
                until Expense.Next() = 0;
            Expense.ModifyAll("Expense Report No.", '');
            Expense.DeleteAll(true);

            ExpenseApprovalSetup.SetRange("Expense User No.", ExpenseUserNo);
            ExpenseApprovalSetup.DeleteAll();
            ExpenseApprovalSetup.Reset();
            ExpenseApprovalSetup.SetRange("Approver No.", ExpenseUserNo);
            ExpenseApprovalSetup.DeleteAll();
            ExpenseApprovalSetup.Reset();

            if ExpenseUser.Get(ExpenseUserNo) then
                ExpenseUser.Delete(true);
        end;

        foreach EmployeeNo in EmployeeNumbers do
            if Employee.Get(EmployeeNo) then
                Employee.Delete(true);

        foreach CategoryCode in CategoryCodes do begin
            ExpenseSubcategory.SetRange("Expense Category Code", CategoryCode);
            ExpenseSubcategory.DeleteAll(true);
            if ExpenseCategory.Get(CategoryCode) then
                ExpenseCategory.Delete(true);
        end;
    end;

}
