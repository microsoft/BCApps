// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.TestLibraries.Environment;

codeunit 148363 "Expense Report UI Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Expense Report] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryExpenseAgent: Codeunit "Library - Expense Agent";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure OpenExpenseAppOnCardVisibleWhenAgentEnabled()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO] App navigation is visible on the report card when the agent is enabled.
        Initialize();

        // [GIVEN] An on-premises report with the agent enabled and approval workflow disabled.
        EnvironmentInfoTestLibrary.SetAppId('NAV');
        BindSubscription(EnvironmentInfoTestLibrary);
        CreateReport(ExpenseReportHeader, true);

        // [WHEN] The report card is opened.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [THEN] Open Expense App is visible.
        Assert.IsTrue(ExpenseReportPage.OpenExpenseApp.Visible(), 'App navigation must be visible when the agent is enabled.');
        ExpenseReportPage.Close();
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        UnbindSubscription(EnvironmentInfoTestLibrary);
    end;

    [Test]
    procedure OpenExpenseAppOnCardHiddenWhenAgentDisabled()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO] App navigation is hidden on the report card when the agent is disabled.
        Initialize();

        // [GIVEN] An on-premises report with the agent and approval workflow disabled.
        EnvironmentInfoTestLibrary.SetAppId('NAV');
        BindSubscription(EnvironmentInfoTestLibrary);
        CreateReport(ExpenseReportHeader, false);

        // [WHEN] The report card is opened.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [THEN] Open Expense App is hidden.
        Assert.IsFalse(ExpenseReportPage.OpenExpenseApp.Visible(), 'App navigation must be hidden when the agent is disabled.');
        ExpenseReportPage.Close();
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        UnbindSubscription(EnvironmentInfoTestLibrary);
    end;

    [Test]
    procedure OpenExpenseAppOnListVisibleWhenAgentEnabled()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ExpenseReports: TestPage "Expense Reports";
    begin
        // [SCENARIO] App navigation is available on the report list without selecting a report.
        Initialize();

        // [GIVEN] An on-premises environment with the agent enabled and approval workflow disabled.
        EnvironmentInfoTestLibrary.SetAppId('NAV');
        BindSubscription(EnvironmentInfoTestLibrary);
        SetAgentEnabled(true);

        // [WHEN] The report list is opened.
        ExpenseReports.OpenView();

        // [THEN] Open Expense App is visible without selecting a report.
        Assert.IsTrue(ExpenseReports.OpenExpenseApp.Visible(), 'App navigation must be visible on the report list when the agent is enabled.');
        ExpenseReports.Close();
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        UnbindSubscription(EnvironmentInfoTestLibrary);
    end;

    [Test]
    procedure OpenExpenseAppOnListHiddenWhenAgentDisabled()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ExpenseReports: TestPage "Expense Reports";
    begin
        // [SCENARIO] App navigation is hidden on the report list when the agent is disabled.
        Initialize();

        // [GIVEN] An on-premises environment with the agent and approval workflow disabled.
        EnvironmentInfoTestLibrary.SetAppId('NAV');
        BindSubscription(EnvironmentInfoTestLibrary);
        SetAgentEnabled(false);

        // [WHEN] The report list is opened.
        ExpenseReports.OpenView();

        // [THEN] Open Expense App is hidden.
        Assert.IsFalse(ExpenseReports.OpenExpenseApp.Visible(), 'App navigation must be hidden on the report list when the agent is disabled.');
        ExpenseReports.Close();
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        UnbindSubscription(EnvironmentInfoTestLibrary);
    end;

    local procedure CreateReport(var ExpenseReportHeader: Record "Expense Report Header"; AgentEnabled: Boolean)
    var
        Submitter: Record "Expense User";
    begin
        SetAgentEnabled(AgentEnabled);
        LibraryExpense.CreateExpenseUser(Submitter);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Submitter."No.", '', '');
    end;

    local procedure SetAgentEnabled(AgentEnabled: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryExpenseAgent.BackupExpenseAgentSetup();
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Enable Approval Workflow" := false;
        ExpenseAgentSetup."Enable Agent" := AgentEnabled;
        ExpenseAgentSetup.Modify();
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Report UI Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Report UI Test");
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Report UI Test");
    end;
}
