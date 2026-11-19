// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using System.Automation;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 148367 "Expense Extension Events Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryRandom: Codeunit "Library - Random";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    [Test]
    procedure CopyExpenseFieldsToReportLineEventCanChangeReportLine()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseExtEventsSubscr: Codeunit "Expense Ext. Events Subscr.";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Marker: Text[20];
    begin
        // [SCENARIO] OnAfterCopyExpenseFieldsToReportLine lets subscribers change the expense report line before it is stored.
        Initialize();

        // [GIVEN] A released expense and an expense report for the same expense user.
        CreateReleasedExpense(Expense);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] A subscriber that sets the report line description to a marker.
        Marker := GenerateMarker();
        ExpenseExtEventsSubscr.SetMarkerText(Marker);
        BindSubscription(ExpenseExtEventsSubscr);

        // [WHEN] The expense is added to the expense report.
        ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
        UnbindSubscription(ExpenseExtEventsSubscr);

        // [THEN] The stored report line has the marker description and the event received the expense.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(Marker, ExpenseReportLine.Description, 'The subscriber change to the report line must be stored.');
        Assert.AreEqual(Expense."No.", ExpenseExtEventsSubscr.GetCapturedExpenseNo(), 'The event must receive the source expense.');
        Assert.AreEqual(1, ExpenseExtEventsSubscr.GetCopyExpenseFieldsCount(), 'The event must be raised once per added expense.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure BeforePostExpenseGenJournalLineEventCanSetGLEntryFields()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        GLEntry: Record "G/L Entry";
        ExpenseExtEventsSubscr: Codeunit "Expense Ext. Events Subscr.";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Marker: Text[20];
    begin
        // [SCENARIO] OnBeforePostExpenseGenJournalLine lets subscribers set fields on the posted G/L entries.
        Initialize();

        // [GIVEN] A released expense report.
        CreateReleasedExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] A subscriber that sets the External Document No. on the expense journal lines.
        Marker := GenerateMarker();
        ExpenseExtEventsSubscr.SetMarkerText(Marker);
        BindSubscription(ExpenseExtEventsSubscr);

        // [WHEN] The expense report is posted.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
        UnbindSubscription(ExpenseExtEventsSubscr);

        // [THEN] The event was raised and the G/L entries of the posted document carry the marker.
        Assert.IsTrue(ExpenseExtEventsSubscr.GetBeforePostGenJnlLineCount() >= 1, 'OnBeforePostExpenseGenJournalLine must be raised.');
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.SetRange("External Document No.", Marker);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseLedgerEntryCopyEventsCanChangeEntry()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        ExpenseExtEventsSubscr: Codeunit "Expense Ext. Events Subscr.";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Marker: Text[20];
    begin
        // [SCENARIO] The Expense Ledger Entry copy events are raised during posting and let subscribers change the entry before insert.
        Initialize();

        // [GIVEN] A released expense report.
        CreateReleasedExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] A subscriber that sets the expense ledger entry description when copying from the journal line.
        Marker := GenerateMarker();
        ExpenseExtEventsSubscr.SetMarkerText(Marker);
        BindSubscription(ExpenseExtEventsSubscr);

        // [WHEN] The expense report is posted.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
        UnbindSubscription(ExpenseExtEventsSubscr);

        // [THEN] Both copy events were raised.
        Assert.IsTrue(ExpenseExtEventsSubscr.GetCopyFromPostedLineCount() >= 1, 'OnAfterCopyFromPostedExpenseReportLine must be raised.');
        Assert.IsTrue(ExpenseExtEventsSubscr.GetCopyFromGenJnlLineCount() >= 1, 'OnAfterCopyFromGenJnlLine must be raised.');

        // [THEN] The expense ledger entry of the posted document has the marker description.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        ExpenseLedgerEntry.SetRange(Description, Marker);
        Assert.RecordIsNotEmpty(ExpenseLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GenJournalLineEventValuesReachExpenseLedgerEntry()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        GLEntry: Record "G/L Entry";
        ExpenseExtEventsSubscr: Codeunit "Expense Ext. Events Subscr.";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Marker: Text[20];
    begin
        // [SCENARIO] OnBeforePostExpenseGenJournalLine is raised before the expense ledger entry copies the journal line.
        Initialize();

        // [GIVEN] A released expense report.
        CreateReleasedExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] A subscriber that only sets the journal line description; the ledger copy subscriber does not change the description.
        Marker := GenerateMarker();
        ExpenseExtEventsSubscr.SetGenJnlLineDescriptionMarker(Marker);
        BindSubscription(ExpenseExtEventsSubscr);

        // [WHEN] The expense report is posted.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
        UnbindSubscription(ExpenseExtEventsSubscr);

        // [THEN] The expense ledger entry of the posted document has the description set on the journal line.
        Assert.IsTrue(ExpenseExtEventsSubscr.GetBeforePostGenJnlLineCount() >= 1, 'OnBeforePostExpenseGenJournalLine must be raised.');
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        ExpenseLedgerEntry.SetRange(Description, Marker);
        Assert.RecordIsNotEmpty(ExpenseLedgerEntry);

        // [THEN] A G/L entry of the posted document has the description set on the journal line.
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.SetRange(Description, Marker);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PostExpenseReportEventsAreRaisedOnce()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseExtEventsSubscr: Codeunit "Expense Ext. Events Subscr.";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] OnBeforePostExpenseReport and OnAfterPostExpenseReport are raised once per posted expense report.
        Initialize();

        // [GIVEN] A released expense report.
        CreateReleasedExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] A subscriber that counts the post events.
        BindSubscription(ExpenseExtEventsSubscr);

        // [WHEN] The expense report is posted.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
        UnbindSubscription(ExpenseExtEventsSubscr);

        // [THEN] Each event was raised once and the after event received the posted report outside preview mode.
        Assert.AreEqual(1, ExpenseExtEventsSubscr.GetBeforePostExpenseReportCount(), 'OnBeforePostExpenseReport must be raised once.');
        Assert.AreEqual(1, ExpenseExtEventsSubscr.GetAfterPostExpenseReportCount(), 'OnAfterPostExpenseReport must be raised once.');
        Assert.AreNotEqual('', ExpenseExtEventsSubscr.GetCapturedPostedExpenseReportNo(), 'OnAfterPostExpenseReport must receive the posted expense report.');
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        Assert.AreEqual(PostedExpenseReportHeader."No.", ExpenseExtEventsSubscr.GetCapturedPostedExpenseReportNo(), 'OnAfterPostExpenseReport must receive the posted expense report.');
        Assert.IsFalse(ExpenseExtEventsSubscr.GetCapturedPreviewMode(), 'PreviewMode must be false for regular posting.');
    end;

    [Test]
    procedure PerDiemCalculationEventCanOverrideAmount()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseExtEventsSubscr: Codeunit "Expense Ext. Events Subscr.";
        ExpensePerDiemCalculation: Codeunit "Expense Per Diem Calculation";
        TripDate: Date;
        BaseRate: Decimal;
        PerDiemAmount: Decimal;
    begin
        // [SCENARIO] OnAfterCalculatePerDiemForSingleDay lets subscribers override the calculated per diem amount.
        Initialize();

        // [GIVEN] Per diem calculation using full calendar days and a trip covering one full day.
        if not ExpenseAgentSetup.Get() then
            ExpenseAgentSetup.Init();
        ExpenseAgentSetup."Full Per-Diem Calculation" := ExpenseAgentSetup."Full Per-Diem Calculation"::"Full Calendar Day";
        ExpensePerDiemCalculation.SetExpenseAgentSetup(ExpenseAgentSetup);
        TripDate := WorkDate();
        BaseRate := 100;

        // [WHEN] The per diem is calculated without a subscriber.
        PerDiemAmount := ExpensePerDiemCalculation.CalculatePerDiemForSingleDay(TripDate, BaseRate, CreateDateTime(TripDate, 000000T), CreateDateTime(TripDate, 235900T));

        // [THEN] The full base rate is returned.
        Assert.AreEqual(BaseRate, PerDiemAmount, 'A full calendar day must return the base rate.');

        // [GIVEN] A subscriber that overrides the per diem amount.
        ExpenseExtEventsSubscr.SetPerDiemAmountOverride(42);
        BindSubscription(ExpenseExtEventsSubscr);

        // [WHEN] The per diem is calculated again.
        PerDiemAmount := ExpensePerDiemCalculation.CalculatePerDiemForSingleDay(TripDate, BaseRate, CreateDateTime(TripDate, 000000T), CreateDateTime(TripDate, 235900T));
        UnbindSubscription(ExpenseExtEventsSubscr);

        // [THEN] The overridden amount is returned and the subscriber received the base rate.
        Assert.AreEqual(42, PerDiemAmount, 'The subscriber must be able to override the per diem amount.');
        Assert.AreEqual(BaseRate, ExpenseExtEventsSubscr.GetCapturedBaseRate(), 'The event must receive the base rate.');
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        ExpensePostingGroup: Record "Expense Posting Group";
        UserSetup: Record "User Setup";
        User: Record User;
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Extension Events Test");
        LibraryVariableStorage.Clear();
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        UserSetup.DeleteAll();

        // Remove test-created users to stay within the CI license user cap; keep the current session user.
        User.SetFilter("User Security ID", '<>%1', UserSecurityId());
        User.DeleteAll();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := '';
        GeneralLedgerSetup.Modify();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Extension Events Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryERMCountryData.UpdateLocalData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        ExpensePostingGroup.DeleteAll();
        Workflow.DeleteAll();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Extension Events Test");
    end;

    local procedure CreateReleasedExpense(var Expense: Record Expense)
    var
        Employee: Record Employee;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseWithZeroVATPostingSetup(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandInt(100));

        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
    end;

    local procedure CreateReleasedExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; var Expense: Record Expense)
    var
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        CreateReleasedExpense(Expense);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
        CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualRelease();
    end;

    local procedure FindPostedExpenseReport(var PostedExpenseReportHeader: Record "Posted Expense Report Header"; Expense: Record Expense)
    begin
        PostedExpenseReportHeader.SetRange("Expense User No.", Expense."Expense User No.");
        PostedExpenseReportHeader.FindFirst();
    end;

    local procedure GenerateMarker(): Text[20]
    begin
        exit(CopyStr(UpperCase(LibraryUtility.GenerateRandomAlphabeticText(20, 1)), 1, 20));
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
