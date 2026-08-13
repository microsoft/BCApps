// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;

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
        ApprovedScenarioPrefixTok: Label 'Activity APPROVED ', Locked = true;
        PostedScenarioPrefixTok: Label 'Activity RESUBMITTED POSTED ', Locked = true;
        SubmitterScenarioPrefixTok: Label 'Activity Submitter ', Locked = true;
        ApproverScenarioPrefixTok: Label 'Activity Approver ', Locked = true;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
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

        // [WHEN] The other report is rejected, resubmitted, approved, and moved to a posted source fixture.
        // Real financial posting and activity reassignment are covered by Expense Report Posting Test.
        SubmitReport(ResubmittedPostedReport, SubmitterExpenseUser);
        RejectAndReopenReport(
            ResubmittedPostedReport, ApproverExpenseUser, 'Persistent send back ' + RunToken);
        SubmitReport(ResubmittedPostedReport, SubmitterExpenseUser);
        ApproveReport(ResubmittedPostedReport, ApproverExpenseUser);
        ResubmittedPostedReport.Get(ResubmittedPostedReport."No.");
        ResubmittedPostedSubjectID := ResubmittedPostedReport.SystemId;
        MoveReportToPostedScenario(ResubmittedPostedReport, PostedExpenseReportHeader);
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
        VerifyOnlyCurrentScenariosRemain();
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        BindSubscription(APITestAuthHelper);
        CleanupPreviousScenarios();
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
        LibraryExpense.CreateExpenseUser(SubmitterExpenseUser);
        SubmitterExpenseUser.Name := CopyStr('Activity Submitter ' + RunToken, 1, MaxStrLen(SubmitterExpenseUser.Name));
        SubmitterExpenseUser."User Id For Approvals" :=
            CopyStr('SUBMITTER-' + RunToken, 1, MaxStrLen(SubmitterExpenseUser."User Id For Approvals"));
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

    local procedure MoveReportToPostedScenario(
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

    local procedure CleanupPreviousScenarios()
    var
        Expense: Record Expense;
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        CategoryCodes: List of [Code[20]];
        EmployeeNumbers: List of [Code[20]];
        ExpenseUserNumbers: List of [Code[20]];
        CategoryCode: Code[20];
        EmployeeNo: Code[20];
        ExpenseUserNo: Code[20];
    begin
        ExpenseUser.SetFilter(
            Name, '%1|%2',
            SubmitterScenarioPrefixTok + '*',
            ApproverScenarioPrefixTok + '*');
        if ExpenseUser.FindSet() then
            repeat
                ExpenseUserNumbers.Add(ExpenseUser."No.");
                if (ExpenseUser."Employee No." <> '') and
                   (not EmployeeNumbers.Contains(ExpenseUser."Employee No."))
                then
                    EmployeeNumbers.Add(ExpenseUser."Employee No.");
            until ExpenseUser.Next() = 0;

        ExpenseActivityLogEntry.SetFilter(
            "Document Description", '%1|%2',
            ApprovedScenarioPrefixTok + '*',
            PostedScenarioPrefixTok + '*');
        ExpenseActivityLogEntry.DeleteAll();

        ExpenseReportHeader.SetFilter(
            Description, '%1|%2',
            ApprovedScenarioPrefixTok + '*',
            PostedScenarioPrefixTok + '*');
        ExpenseReportHeader.DeleteAll(true);

        PostedExpenseReportHeader.SetFilter(
            Description, '%1|%2',
            ApprovedScenarioPrefixTok + '*',
            PostedScenarioPrefixTok + '*');
        PostedExpenseReportHeader.DeleteAll(true);

        foreach ExpenseUserNo in ExpenseUserNumbers do begin
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

        foreach EmployeeNo in EmployeeNumbers do begin
            EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
            if EmployeeLedgerEntry.IsEmpty() then
                if Employee.Get(EmployeeNo) then
                    Employee.Delete(true);
            EmployeeLedgerEntry.Reset();
        end;

        foreach CategoryCode in CategoryCodes do begin
            ExpenseSubcategory.SetRange("Expense Category Code", CategoryCode);
            ExpenseSubcategory.DeleteAll(true);
            if ExpenseCategory.Get(CategoryCode) then
                ExpenseCategory.Delete(true);
        end;

        Commit();
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

    local procedure VerifyOnlyCurrentScenariosRemain()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        ExpenseReportHeader.SetFilter(
            Description, '%1|%2',
            ApprovedScenarioPrefixTok + '*',
            PostedScenarioPrefixTok + '*');
        Assert.RecordCount(ExpenseReportHeader, 1);

        PostedExpenseReportHeader.SetFilter(
            Description, '%1|%2',
            ApprovedScenarioPrefixTok + '*',
            PostedScenarioPrefixTok + '*');
        Assert.RecordCount(PostedExpenseReportHeader, 1);

        ExpenseUser.SetFilter(
            Name, '%1|%2',
            SubmitterScenarioPrefixTok + '*',
            ApproverScenarioPrefixTok + '*');
        Assert.RecordCount(ExpenseUser, 2);
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

}
