// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.TestLibraries.Environment;

codeunit 148329 "Expense Reports API Test"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowAllOutboundRequests;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Expense Report] [API]
    end;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ApproverViewsServiceNameTok: Label 'approverViews', Locked = true;
        ExpenseReportsServiceNameTok: Label 'expenseReports', Locked = true;
        ActiveApproverFilterLbl: Label '$filter=activeApproverExpenseUserNo eq ''%1''', Comment = '%1 = Expense User No.', Locked = true;

    [Test]
    procedure ApproverViewReturnsOnlyActivePendingReports()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        OtherApprover: Record "Expense User";
        ApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        ReportStatus: Enum "Expense Report Status";
        ExpectedReportIds: List of [Guid];
        StatusOrdinal: Integer;
    begin
        // [SCENARIO] Report navigation uses the active approver, not the submitter's configured approver.
        Initialize();

        // [GIVEN] The submitter's configured approver differs from the active approver on reports in every status.
        LibraryExpense.CreateExpenseUser(Submitter);
        CreateApprover(Approver);
        CreateApprover(OtherApprover);
        LibraryExpense.CreateExpenseApprovalSetup(ApprovalSetup, Submitter."No.", OtherApprover."No.");

        foreach StatusOrdinal in ReportStatus.Ordinals() do begin
            ReportStatus := Enum::"Expense Report Status".FromInteger(StatusOrdinal);
            CreateReport(ExpenseReportHeader, Submitter."No.", Approver."No.", ReportStatus);
            if ReportStatus in [ReportStatus::"Pending Approval", ReportStatus::"Interim Approved"] then
                ExpectedReportIds.Add(ExpenseReportHeader.SystemId);
        end;
        CreateReport(ExpenseReportHeader, Submitter."No.", OtherApprover."No.", ReportStatus::"Pending Approval");
        CreateReport(ExpenseReportHeader, Submitter."No.", OtherApprover."No.", ReportStatus::"Interim Approved");
        CreateReport(ExpenseReportHeader, Submitter."No.", '', ReportStatus::"Pending Approval");
        Commit();

        // [WHEN] The active approver's reports are expanded through the API.
        // [THEN] Only its Pending Approval and Interim Approved reports are returned.
        AssertExpandedReports(Approver, ExpectedReportIds);
    end;

    [Test]
    procedure ApproverViewWithoutAssignedReportsReturnsEmpty()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        OtherApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpectedReportIds: List of [Guid];
    begin
        // [SCENARIO] An approver without assigned reports receives an empty collection.
        Initialize();

        // [GIVEN] A pending report is assigned to another approver.
        LibraryExpense.CreateExpenseUser(Submitter);
        CreateApprover(Approver);
        CreateApprover(OtherApprover);
        CreateReport(ExpenseReportHeader, Submitter."No.", OtherApprover."No.", ExpenseReportHeader.Status::"Pending Approval");
        Commit();

        // [WHEN] The unassigned approver's reports are expanded through the API.
        // [THEN] The expanded report collection is empty.
        AssertExpandedReports(Approver, ExpectedReportIds);
    end;

    [Test]
    procedure InterimApprovalMovesReportBetweenApproverViews()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
        ExpectedReportIds: List of [Guid];
        EmptyReportIds: List of [Guid];
    begin
        // [SCENARIO] Interim approval moves the report from the interim approver's API view to the final approver's.
        Initialize();

        // [GIVEN] A pending report has an interim approver and a different final approver.
        LibraryExpense.CreateExpenseUser(Submitter);
        CreateApprover(InterimApprover);
        CreateApprover(FinalApprover);
        LibraryExpense.CreateExpenseApprovalSetup(ApprovalSetup, Submitter."No.", FinalApprover."No.");
        CreateReport(ExpenseReportHeader, Submitter."No.", InterimApprover."No.", ExpenseReportHeader.Status::"Pending Approval");
        ExpenseReportHeader."Interim Approver No." := InterimApprover."No.";
        ExpenseReportHeader."Final Approver No." := FinalApprover."No.";
        ExpenseReportHeader.Modify();
        ExpectedReportIds.Add(ExpenseReportHeader.SystemId);
        Commit();

        // [GIVEN] The report is visible only in the interim approver's expanded report collection.
        AssertExpandedReports(InterimApprover, ExpectedReportIds);
        AssertExpandedReports(FinalApprover, EmptyReportIds);

        // [WHEN] The interim approver approves the report.
        ExpenseReportApprovalMgmt.Approve(ExpenseReportHeader, InterimApprover."No.");

        // [THEN] The report is Interim Approved and assigned to the final approver.
        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::"Interim Approved");
        ExpenseReportHeader.TestField("Approver Expense User No.", FinalApprover."No.");
        Commit();

        // [THEN] API expansion returns the report only for the final approver.
        AssertExpandedReports(InterimApprover, EmptyReportIds);
        AssertExpandedReports(FinalApprover, ExpectedReportIds);
    end;

    [Test]
    procedure ReportsAPIFiltersByActiveApproverWithoutStatusRestriction()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        OtherApprover: Record "Expense User";
        ApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        Response: JsonObject;
        Reports: JsonToken;
        ExpectedReportIds: List of [Guid];
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] A direct active-approver filter exposes the API property without the navigation's status restriction.
        Initialize();

        // [GIVEN] Open and pending reports share an active approver who differs from the configured approver.
        LibraryExpense.CreateExpenseUser(Submitter);
        CreateApprover(Approver);
        CreateApprover(OtherApprover);
        LibraryExpense.CreateExpenseApprovalSetup(ApprovalSetup, Submitter."No.", OtherApprover."No.");
        CreateReport(ExpenseReportHeader, Submitter."No.", Approver."No.", ExpenseReportHeader.Status::"Pending Approval");
        ExpectedReportIds.Add(ExpenseReportHeader.SystemId);
        CreateReport(ExpenseReportHeader, Submitter."No.", Approver."No.", ExpenseReportHeader.Status::Open);
        ExpectedReportIds.Add(ExpenseReportHeader.SystemId);
        CreateReport(ExpenseReportHeader, Submitter."No.", OtherApprover."No.", ExpenseReportHeader.Status::"Pending Approval");
        Commit();

        // [WHEN] The report collection is filtered directly by activeApproverExpenseUserNo.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Reports API", ExpenseReportsServiceNameTok);
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(
            TargetURL, StrSubstNo(ActiveApproverFilterLbl, Approver."No."));
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Both matching reports expose the active approver, regardless of report status.
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'The report response must be valid JSON.');
        Assert.IsTrue(Response.Get('value', Reports), 'The report response must contain a collection.');
        AssertReports(Reports.AsArray(), ExpectedReportIds, Approver."No.");
    end;

    [Test]
    procedure OnPremisesExpenseReportUrlUsesCanonicalGuid()
    var
        EAHttpClient: Codeunit "EA Http Client";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ReportSystemId: Guid;
        ExpenseAppBaseUrl: Text;
        ExpenseReportUrl: Text;
    begin
        // [SCENARIO] On-premises report links use a lowercase GUID without braces.
        Initialize();

        // [GIVEN] An on-premises environment and a report identity containing uppercase letters.
        EnvironmentInfoTestLibrary.SetAppId('NAV');
        BindSubscription(EnvironmentInfoTestLibrary);
        Evaluate(ReportSystemId, '{ABCDEF01-2345-6789-ABCD-EF0123456789}');

        // [WHEN] Dashboard and report URLs are generated.
        ExpenseAppBaseUrl := EAHttpClient.GetExpenseAppBaseUrl();
        ExpenseReportUrl := EAHttpClient.GetExpenseReportUrl(ReportSystemId);

        // [THEN] The dashboard URL is preserved and the report URL uses a lowercase GUID without braces.
        Assert.AreEqual('http://localhost:5173/', ExpenseAppBaseUrl, 'The on-premises dashboard URL must be preserved.');
        Assert.AreEqual(
            'http://localhost:5173/reports/abcdef01-2345-6789-abcd-ef0123456789',
            ExpenseReportUrl,
            'The report URL must contain the reports path and the canonical GUID.');
        UnbindSubscription(EnvironmentInfoTestLibrary);
    end;

    local procedure AssertExpandedReports(Approver: Record "Expense User"; ExpectedReportIds: List of [Guid])
    var
        Response: JsonObject;
        Reports: JsonToken;
        TargetURL: Text;
        ResponseText: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(Approver.SystemId), Page::"Approver View API", ApproverViewsServiceNameTok);
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(TargetURL, '$expand=expenseReports');
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        Assert.IsTrue(Response.ReadFrom(ResponseText), 'The approver response must be valid JSON.');
        Assert.IsTrue(Response.Get('expenseReports', Reports), 'The approver response must contain expanded expense reports.');
        AssertReports(Reports.AsArray(), ExpectedReportIds, Approver."No.");
    end;

    local procedure AssertReports(Reports: JsonArray; ExpectedReportIds: List of [Guid]; ExpectedApproverNo: Code[20])
    var
        ReportToken: JsonToken;
        ReportObject: JsonObject;
        IdToken: JsonToken;
        ApproverToken: JsonToken;
        ActualReportIds: List of [Guid];
        ReportSystemId: Guid;
    begin
        Assert.AreEqual(ExpectedReportIds.Count(), Reports.Count(), 'The API must return exactly the expected reports.');
        foreach ReportToken in Reports do begin
            ReportObject := ReportToken.AsObject();
            Assert.IsTrue(ReportObject.Get('id', IdToken), 'Each report must expose its identity.');
            Evaluate(ReportSystemId, IdToken.AsValue().AsText());
            Assert.IsTrue(ExpectedReportIds.Contains(ReportSystemId), 'The API must not return an unexpected report.');
            Assert.IsFalse(ActualReportIds.Contains(ReportSystemId), 'The API must not return duplicate reports.');
            ActualReportIds.Add(ReportSystemId);
            Assert.IsTrue(ReportObject.Get('activeApproverExpenseUserNo', ApproverToken), 'Each report must expose its active approver.');
            Assert.AreEqual(ExpectedApproverNo, ApproverToken.AsValue().AsText(), 'Each report must identify the expected active approver.');
        end;
    end;

    local procedure CreateReport(var ExpenseReportHeader: Record "Expense Report Header"; SubmitterNo: Code[20]; ApproverNo: Code[20]; ReportStatus: Enum "Expense Report Status")
    begin
        Clear(ExpenseReportHeader);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, SubmitterNo, '', '');
        ExpenseReportHeader.Status := ReportStatus;
        ExpenseReportHeader."Approver Expense User No." := ApproverNo;
        ExpenseReportHeader.Modify();
    end;

    local procedure CreateApprover(var ExpenseUser: Record "Expense User")
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser."Can Approve" := true;
        ExpenseUser."Unlimited Approval" := true;
        ExpenseUser."User Id For Approvals" := CopyStr(UserId(), 1, MaxStrLen(ExpenseUser."User Id For Approvals"));
        ExpenseUser.Modify();
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Reports API Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Reports API Test");
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Reports API Test");
    end;
}
