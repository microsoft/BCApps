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
    procedure ViewInExpenseAppVisibleWhenAgentEnabled()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO] The expense app link is visible when the agent is enabled.
        Initialize();

        // [GIVEN] An on-premises report with the agent enabled and approval workflow disabled.
        EnvironmentInfoTestLibrary.SetAppId('NAV');
        BindSubscription(EnvironmentInfoTestLibrary);
        CreateReport(ExpenseReportHeader, true);

        // [WHEN] The report card is opened.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [THEN] View in Expense App is visible.
        Assert.IsTrue(ExpenseReportPage.ViewInExpenseApp.Visible(), 'The report link must be visible when the agent is enabled.');
        ExpenseReportPage.Close();
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        UnbindSubscription(EnvironmentInfoTestLibrary);
    end;

    [Test]
    procedure ViewInExpenseAppHiddenWhenAgentDisabled()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO] The expense app link is hidden when the agent is disabled.
        Initialize();

        // [GIVEN] An on-premises report with the agent and approval workflow disabled.
        EnvironmentInfoTestLibrary.SetAppId('NAV');
        BindSubscription(EnvironmentInfoTestLibrary);
        CreateReport(ExpenseReportHeader, false);

        // [WHEN] The report card is opened.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [THEN] View in Expense App is hidden.
        Assert.IsFalse(ExpenseReportPage.ViewInExpenseApp.Visible(), 'The report link must be hidden when the agent is disabled.');
        ExpenseReportPage.Close();
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        UnbindSubscription(EnvironmentInfoTestLibrary);
    end;

    local procedure CreateReport(var ExpenseReportHeader: Record "Expense Report Header"; AgentEnabled: Boolean)
    var
        Submitter: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryExpenseAgent.BackupExpenseAgentSetup();
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Enable Approval Workflow" := false;
        ExpenseAgentSetup."Enable Agent" := AgentEnabled;
        ExpenseAgentSetup.Modify();
        LibraryExpense.CreateExpenseUser(Submitter);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Submitter."No.", '', '');
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
