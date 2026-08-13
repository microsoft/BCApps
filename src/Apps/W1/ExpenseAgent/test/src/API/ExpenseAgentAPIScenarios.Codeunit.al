// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.HumanResources.Employee;

/// <summary>
/// Creates persistent Expense Agent API scenarios for end-to-end and manual UI verification.
/// </summary>
codeunit 148340 "Expense Agent API Scenarios"
{
    Subtype = Test;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryRandom: Codeunit "Library - Random";
        APITestAuthHelper: Codeunit "Expense API Test Auth Helper";
        ReportsServiceNameTok: Label 'expenseReports', Locked = true;
        ExpenseUsersServiceNameTok: Label 'expenseUsers', Locked = true;
        ActivityServiceNameTok: Label 'expenseActivityLogEntries', Locked = true;
        SubmitActionTok: Label 'Microsoft.NAV.releaseAndMarkPendingApprovalExpenseReport', Locked = true;
        ApproveActionTok: Label 'Microsoft.NAV.approvedExpenseReport', Locked = true;
        RejectAndReopenActionTok: Label 'Microsoft.NAV.rejectAndReopenExpenseReport', Locked = true;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure CreatePersistentActivityScenarios()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ApprovedReport: Record "Expense Report Header";
        ResubmittedPostedReport: Record "Expense Report Header";
        PostedActivity: Record "Expense Activity Log Entry";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ResubmittedPostedSubjectID: Guid;
        RunToken: Code[8];
    begin
        // [SCENARIO] Persist representative Web App activity scenarios for API and UI verification.
        Initialize();
        RunToken := CreateRunToken();
        CreateScenarioSetup(
            SubmitterExpenseUser, ApproverExpenseUser,
            ExpenseCategory, ExpenseSubCategory, ExpensePaymentMethod, RunToken);

        // [GIVEN] Two valid draft reports with unique scenario descriptions.
        CreateScenarioReport(
            ApprovedReport, SubmitterExpenseUser, ExpenseCategory, ExpenseSubCategory,
            ExpensePaymentMethod, RunToken, 'APPROVED');
        CreateScenarioReport(
            ResubmittedPostedReport, SubmitterExpenseUser, ExpenseCategory, ExpenseSubCategory,
            ExpensePaymentMethod, RunToken, 'RESUBMITTED POSTED');
        Commit();

        // [WHEN] One report follows the simple submit and approve flow.
        SubmitReport(ApprovedReport, SubmitterExpenseUser);
        ApproveReport(ApprovedReport, ApproverExpenseUser);

        // [WHEN] The other report is rejected, resubmitted, approved, and posted.
        SubmitReport(ResubmittedPostedReport, SubmitterExpenseUser);
        RejectAndReopenReport(
            ResubmittedPostedReport, ApproverExpenseUser, 'Persistent send back ' + RunToken);
        SubmitReport(ResubmittedPostedReport, SubmitterExpenseUser);
        ApproveReport(ResubmittedPostedReport, ApproverExpenseUser);
        ResubmittedPostedReport.Get(ResubmittedPostedReport."No.");
        ResubmittedPostedSubjectID := ResubmittedPostedReport.SystemId;
        ExpenseReportPost.PostExpenseReport(ResubmittedPostedReport);
        Commit();

        // [THEN] The active report is approved and the end-to-end report is posted.
        ApprovedReport.Get(ApprovedReport."No.");
        Assert.AreEqual(ApprovedReport.Status::Approved, ApprovedReport.Status, 'Approved scenario has the wrong status.');
        Assert.IsFalse(
            ResubmittedPostedReport.Get(ResubmittedPostedReport."No."),
            'Resubmitted and posted scenario must no longer have an active report.');

        PostedActivity.SetRange("Subject Table ID", Database::"Expense Report Header");
        PostedActivity.SetRange("Subject System ID", ResubmittedPostedSubjectID);
        PostedActivity.SetCurrentKey("Subject Table ID", "Subject System ID", "Occurred At", "Entry No.");
        PostedActivity.FindLast();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::Posted, PostedActivity."Event Type", 'The latest posted scenario entry must be Posted.');
        PostedExpenseReportHeader.GetBySystemId(PostedActivity."Source Record System ID");

        // [THEN] Report and user-scoped APIs expose the persisted activity.
        VerifyActiveReportActivity(ApprovedReport.SystemId, Enum::"Expense Activity Event Type"::Approved);
        VerifyPostedReportActivity(PostedExpenseReportHeader.SystemId, ResubmittedPostedSubjectID);
        VerifySubmitterHistory(
            SubmitterExpenseUser.SystemId,
            ApprovedReport.SystemId, ResubmittedPostedSubjectID);
        VerifyApproverHistory(
            ApproverExpenseUser.SystemId,
            ApprovedReport.SystemId, ResubmittedPostedSubjectID);
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        BindSubscription(APITestAuthHelper);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();

        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Enable Agent" := true;
        ExpenseAgentSetup."Enable Approval Workflow" := false;
        ExpenseAgentSetup."Use Rules" := false;
        ExpenseAgentSetup.Modify(false);
        Commit();
    end;

    local procedure CreateScenarioSetup(
        var SubmitterExpenseUser: Record "Expense User";
        var ApproverExpenseUser: Record "Expense User";
        var ExpenseCategory: Record "Expense Category";
        var ExpenseSubCategory: Record "Expense Subcategory";
        var ExpensePaymentMethod: Record "Expense Payment Method";
        RunToken: Code[8]
    )
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        Employee: Record Employee;
    begin
        SubmitterExpenseUser.SetRange("User Id For Approvals", UserId());
        SubmitterExpenseUser.ModifyAll("User Id For Approvals", '');
        SubmitterExpenseUser.Reset();

        LibraryExpense.CreateExpenseUser(SubmitterExpenseUser);
        SubmitterExpenseUser.Name := CopyStr('Activity Submitter ' + RunToken, 1, MaxStrLen(SubmitterExpenseUser.Name));
        SubmitterExpenseUser."User Id For Approvals" :=
            CopyStr(UserId(), 1, MaxStrLen(SubmitterExpenseUser."User Id For Approvals"));
        SubmitterExpenseUser.Modify();

        LibraryExpense.CreateExpenseUser(ApproverExpenseUser);
        ApproverExpenseUser.Name := CopyStr('Activity Approver ' + RunToken, 1, MaxStrLen(ApproverExpenseUser.Name));
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
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.FindExpensePaymentMethod(
            ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        Employee.Get(SubmitterExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
    end;

    local procedure CreateScenarioReport(
        var ExpenseReportHeader: Record "Expense Report Header";
        SubmitterExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePaymentMethod: Record "Expense Payment Method";
        RunToken: Code[8];
        ScenarioName: Text[20]
    )
    var
        Expense: Record Expense;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        LibraryExpense.CreateExpenseWithZeroVATPostingSetup(
            Expense,
            SubmitterExpenseUser."No.",
            ExpenseCategory.Code,
            ExpenseSubCategory.Code,
            '',
            true,
            '',
            LibraryRandom.RandIntInRange(10, 500));
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        LibraryExpense.CreateExpenseReport(
            ExpenseReportHeader, SubmitterExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        ExpenseReportHeader.Description :=
            CopyStr('Activity ' + ScenarioName + ' ' + RunToken, 1, MaxStrLen(ExpenseReportHeader.Description));
        ExpenseReportHeader.Modify();
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
    end;

    local procedure SubmitReport(var ExpenseReportHeader: Record "Expense Report Header"; SubmitterExpenseUser: Record "Expense User")
    var
        RequestBody: JsonObject;
    begin
        RequestBody.Add('submitterExpenseUserNo', SubmitterExpenseUser."No.");
        InvokeReportAction(ExpenseReportHeader.SystemId, SubmitActionTok, RequestBody);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
    end;

    local procedure ApproveReport(var ExpenseReportHeader: Record "Expense Report Header"; ApproverExpenseUser: Record "Expense User")
    var
        RequestBody: JsonObject;
    begin
        RequestBody.Add('approverExpenseUserNo', ApproverExpenseUser."No.");
        InvokeReportAction(ExpenseReportHeader.SystemId, ApproveActionTok, RequestBody);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
    end;

    local procedure RejectAndReopenReport(
        var ExpenseReportHeader: Record "Expense Report Header";
        ApproverExpenseUser: Record "Expense User";
        RejectReason: Text
    )
    var
        RequestBody: JsonObject;
    begin
        RequestBody.Add('approverExpenseUserNo', ApproverExpenseUser."No.");
        RequestBody.Add('rejectReason', RejectReason);
        InvokeReportAction(ExpenseReportHeader.SystemId, RejectAndReopenActionTok, RequestBody);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
    end;

    local procedure InvokeReportAction(ReportSystemID: Guid; ActionName: Text; RequestBody: JsonObject)
    var
        ResponseText: Text;
        RequestBodyText: Text;
        TargetURL: Text;
    begin
        RequestBody.WriteTo(RequestBodyText);
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ReportSystemID), Page::"Expense Reports API", ReportsServiceNameTok, ActionName);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBodyText, ResponseText, 200);
    end;

    local procedure VerifyActiveReportActivity(ReportSystemID: Guid; EventType: Enum "Expense Activity Event Type")
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ReportSystemID), Page::"Expense Reports API", ReportsServiceNameTok, ActivityServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        VerifyResponseContains(ResponseText, Format(ReportSystemID), Format(EventType));
    end;

    local procedure VerifyPostedReportActivity(PostedReportSystemID: Guid; SubjectSystemID: Guid)
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(PostedReportSystemID),
            Page::"Posted Expense Reports API",
            'postedExpenseReports',
            ActivityServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        VerifyResponseContains(ResponseText, Format(SubjectSystemID), 'Posted');
    end;

    local procedure VerifySubmitterHistory(
        ExpenseUserSystemID: Guid;
        ApprovedSubjectID: Guid;
        PostedSubjectID: Guid
    )
    var
        ResponseText: Text;
    begin
        GetExpenseUserHistory(ResponseText, ExpenseUserSystemID, 'Submitter');
        VerifyResponseContains(ResponseText, Format(ApprovedSubjectID), '');
        VerifyResponseContains(ResponseText, Format(PostedSubjectID), '');
    end;

    local procedure VerifyApproverHistory(
        ExpenseUserSystemID: Guid;
        ApprovedSubjectID: Guid;
        PostedSubjectID: Guid
    )
    var
        ResponseText: Text;
    begin
        GetExpenseUserHistory(ResponseText, ExpenseUserSystemID, 'Approver');
        VerifyResponseContains(ResponseText, Format(ApprovedSubjectID), '');
        VerifyResponseContains(ResponseText, Format(PostedSubjectID), '');
    end;

    local procedure GetExpenseUserHistory(var ResponseText: Text; ExpenseUserSystemID: Guid; HistoryRole: Text)
    var
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseUserSystemID),
            Page::"Expense Users API",
            ExpenseUsersServiceNameTok,
            ActivityServiceNameTok);
        TargetURL += '?$filter=historyActorRole eq ''' + HistoryRole + '''';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
    end;

    local procedure VerifyResponseContains(ResponseText: Text; ExpectedID: Text; ExpectedEventType: Text)
    begin
        ResponseText := LowerCase(ResponseText);
        ExpectedID := LowerCase(LibraryGraphMgt.StripBrackets(ExpectedID));
        Assert.AreNotEqual(0, StrPos(ResponseText, ExpectedID), 'The API response does not contain the expected subject ID.');
        if ExpectedEventType <> '' then
            Assert.AreNotEqual(
                0,
                StrPos(ResponseText, LowerCase(ExpectedEventType)),
                'The API response does not contain the expected event type.');
    end;

    local procedure CreateRunToken(): Code[8]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 8));
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
