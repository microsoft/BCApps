// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using System.Automation;
using System.TestLibraries.Utilities;

codeunit 148367 "Exp. Report Change Log Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        DimensionTextTok: Label '%1: %2', Locked = true;
        StatusMustNotChangeErr: Label 'The status of the expense report must not change.';
        FieldValueMustBeUpdatedErr: Label 'The field must have the new value.';
        ChangeLogEntryNotFoundErr: Label 'The change log entry for table %1, field %2, line %3 was not found.', Comment = '%1 = Table ID, %2 = Field No., %3 = Line No.';
        NewValueMustBeLoggedErr: Label 'The change log entry must contain the new value.';
        OldValueMustBeLoggedErr: Label 'The change log entry must contain the old value.';
        FieldCaptionMustBeLoggedErr: Label 'The change log entry must contain the caption of the changed field.';
        UserMustBeLoggedErr: Label 'The change log entry must contain the user who made the change.';
        ExpenseNoMustBeLoggedErr: Label 'The change log entry must contain the expense number of the line.';
        PolicyEvalVersionMustChangeErr: Label 'An accounting correction must preserve the existing policy invalidation behavior.';
        ChangeMustBeShownErr: Label 'The change history must show the change.';
        ChangeHistoryMustBeDeletedErr: Label 'The change history must be deleted together with the expense report.';
        RuleViolationPresentOnLineErr: Label 'There are one or more rule violations in this expense report. Check the expenses marked for review before submitting again.';

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure HeaderDimensionChangeOnReleasedReportIsLoggedWithoutReopening()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        GlobalDimensionValue: Record "Dimension Value";
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
        ExpectedDimensionText: Text;
    begin
        // [SCENARIO 640772] The accountant changes a header dimension on a released expense report without reopening it, and the change is logged.
        Initialize();

        // [GIVEN] Released expense report with one line.
        CreateReleasedExpenseReport(ExpenseReportHeader);

        // [GIVEN] New value of global dimension 1, which is used as shortcut dimension 1.
        LibraryDimension.GetGlobalDimCodeValue(1, GlobalDimensionValue);
        LibraryDimension.CreateDimensionValue(DimensionValue, GlobalDimensionValue."Dimension Code");
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Shortcut Dimension 1 Code" := DimensionValue."Dimension Code";
        GeneralLedgerSetup.Modify();
        ExpectedDimensionText := StrSubstNo(DimensionTextTok, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Change "Shortcut Dimension 1 Code" on the released expense report.
        ExpenseReportHeader.SetHideValidationDialog(true);
        ExpenseReportHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [THEN] The expense report is still released and has the new dimension value.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseReportHeader.Status::Released, ExpenseReportHeader.Status, StatusMustNotChangeErr);
        Assert.AreEqual(DimensionValue.Code, ExpenseReportHeader."Shortcut Dimension 1 Code", FieldValueMustBeUpdatedErr);

        // [THEN] The header dimension change is logged with the user who made it.
        FindChangeLogEntry(
            ExpReportChangeLogEntry, Database::"Expense Report Header", ExpenseReportHeader.SystemId, 0,
            Database::"Expense Report Header", ExpenseReportHeader.FieldNo("Dimension Set ID"));
        VerifyChangeLogEntryAuditInfo(ExpReportChangeLogEntry);
        Assert.IsTrue(StrPos(ExpReportChangeLogEntry."New Value", ExpectedDimensionText) > 0, NewValueMustBeLoggedErr);
        Assert.IsTrue(StrPos(ExpReportChangeLogEntry."Old Value", ExpectedDimensionText) = 0, OldValueMustBeLoggedErr);

        // [THEN] The line gets the new dimension value, and the line dimension change is logged.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        Assert.AreEqual(DimensionValue.Code, ExpenseReportLine."Shortcut Dimension 1 Code", FieldValueMustBeUpdatedErr);
        FindChangeLogEntry(
            ExpReportChangeLogEntry, Database::"Expense Report Header", ExpenseReportHeader.SystemId, ExpenseReportLine."Line No.",
            Database::"Expense Report Line", ExpenseReportLine.FieldNo("Dimension Set ID"));
        VerifyChangeLogEntryAuditInfo(ExpReportChangeLogEntry);
        Assert.IsTrue(StrPos(ExpReportChangeLogEntry."New Value", ExpectedDimensionText) > 0, NewValueMustBeLoggedErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure LineAccountingFieldsCanBeChangedOnReleasedReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        OldExpenseReportLine: Record "Expense Report Line";
        NewMerchantName: Text[100];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 640772] The accountant changes the merchant and the billing details of a line on a released expense report without reopening it.
        Initialize();

        // [GIVEN] Released expense report with one line that is not billable.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        OldExpenseReportLine := ExpenseReportLine;

        // [WHEN] Change "Merchant Name", Billable and "Billable to Customer" on the line.
        NewMerchantName := CopyStr(LibraryRandom.RandText(50), 1, MaxStrLen(NewMerchantName));
        CustomerNo := LibrarySales.CreateCustomerNo();
        ExpenseReportLine.Validate("Merchant Name", NewMerchantName);
        ExpenseReportLine.Validate(Billable, true);
        ExpenseReportLine.Validate("Billable to Customer", CustomerNo);
        ExpenseReportLine.Modify(true);

        // [THEN] The expense report is still released and the line has the new values.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseReportHeader.Status::Released, ExpenseReportHeader.Status, StatusMustNotChangeErr);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(NewMerchantName, ExpenseReportLine."Merchant Name", FieldValueMustBeUpdatedErr);
        Assert.AreEqual(CustomerNo, ExpenseReportLine."Billable to Customer", FieldValueMustBeUpdatedErr);

        // [THEN] Each change is logged with the old value, the new value and the user.
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("Merchant Name"), OldExpenseReportLine."Merchant Name", NewMerchantName);
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo(Billable), Format(OldExpenseReportLine.Billable), Format(true));
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("Billable to Customer"), OldExpenseReportLine."Billable to Customer", CustomerNo);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AccountingChangeOnReleasedReportInvalidatesPolicyEvaluation()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        OldExpenseReportLine: Record "Expense Report Line";
        NewMerchantVATRegistrationNo: Text[20];
    begin
        // [SCENARIO 640772] Logging accounting corrections preserves the existing policy invalidation behavior.
        Initialize();

        // [GIVEN] Released expense report with one line.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        OldExpenseReportLine := ExpenseReportLine;

        // [WHEN] Change "Merchant VAT Registration No." on the line.
        NewMerchantVATRegistrationNo := CopyStr(LibraryRandom.RandText(MaxStrLen(NewMerchantVATRegistrationNo)), 1, MaxStrLen(NewMerchantVATRegistrationNo));
        ExpenseReportLine.Validate("Merchant VAT Registration No.", NewMerchantVATRegistrationNo);
        ExpenseReportLine.Modify(true);

        // [THEN] The policy evaluation version of the line is incremented as before.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(OldExpenseReportLine."Policy Eval Version" + 1, ExpenseReportLine."Policy Eval Version", PolicyEvalVersionMustChangeErr);

        // [THEN] The change is logged.
        VerifyLineChangeLogEntry(
            ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("Merchant VAT Registration No."),
            OldExpenseReportLine."Merchant VAT Registration No.", NewMerchantVATRegistrationNo);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ChangesOnOpenReportAreNotLogged()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
    begin
        // [SCENARIO 640772] Changes made while the expense report is open are part of the preparation and are not logged.
        Initialize();

        // [GIVEN] Open expense report with one line.
        CreateOpenExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);

        // [WHEN] Change "Merchant Name" on the line.
        ExpenseReportLine.Validate("Merchant Name", CopyStr(LibraryRandom.RandText(50), 1, MaxStrLen(ExpenseReportLine."Merchant Name")));
        ExpenseReportLine.Modify(true);

        // [THEN] No change is logged for the expense report.
        ExpReportChangeLogEntry.SetRange("Source Table ID", Database::"Expense Report Header");
        ExpReportChangeLogEntry.SetRange("Source Record System ID", ExpenseReportHeader.SystemId);
        Assert.RecordIsEmpty(ExpReportChangeLogEntry);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ChangeHistoryIsMovedToPostedExpenseReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpenseReportSystemId: Guid;
        ExpenseUserNo: Code[20];
        NewMerchantName: Text[100];
    begin
        // [SCENARIO 640772] The change history of an expense report is kept on the posted expense report.
        Initialize();

        // [GIVEN] Released expense report where the accountant changed "Merchant Name" of the line.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        ExpenseReportSystemId := ExpenseReportHeader.SystemId;
        ExpenseUserNo := ExpenseReportHeader."Expense User No.";
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        NewMerchantName := CopyStr(LibraryRandom.RandText(50), 1, MaxStrLen(NewMerchantName));
        ExpenseReportLine.Validate("Merchant Name", NewMerchantName);
        ExpenseReportLine.Modify(true);

        // [WHEN] Post the expense report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] The change history belongs to the posted expense report.
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUserNo);
        PostedExpenseReportHeader.FindFirst();
        FindChangeLogEntry(
            ExpReportChangeLogEntry, Database::"Posted Expense Report Header", PostedExpenseReportHeader.SystemId, ExpenseReportLine."Line No.",
            Database::"Expense Report Line", ExpenseReportLine.FieldNo("Merchant Name"));
        Assert.AreEqual(NewMerchantName, ExpReportChangeLogEntry."New Value", NewValueMustBeLoggedErr);

        // [THEN] No change history is left for the deleted expense report.
        ExpReportChangeLogEntry.Reset();
        ExpReportChangeLogEntry.SetRange("Source Table ID", Database::"Expense Report Header");
        ExpReportChangeLogEntry.SetRange("Source Record System ID", ExpenseReportSystemId);
        Assert.RecordIsEmpty(ExpReportChangeLogEntry);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ExpenseBillingInformationModalPageHandler')]
    procedure ChangeHistoryActionShowsChangesMadeOnReleasedReportPage()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        ExpReportChangeLogEntries: TestPage "Exp. Report Change Log Entries";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 640772] The accountant changes the billable customer on the page of a released expense report and sees the change in the change history.
        Initialize();

        // [GIVEN] Released expense report with one line.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] The line is made billable to a customer from the "Show Billable Information" action on the "Expense Report" page.
        LibraryVariableStorage.Enqueue(CustomerNo);
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense Report Subform".First();
        ExpenseReportPage."Expense Report Subform"."Show Billable Information".Invoke();
        ExpenseReportPage.Close();

        // [WHEN] Open the change history from the "Expense Report" page.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpReportChangeLogEntries.Trap();
        ExpenseReportPage.ChangeHistory.Invoke();

        // [THEN] The change history shows the new customer, the changed field and the user who changed it.
        Assert.IsTrue(ExpReportChangeLogEntries.FindFirstField("New Value", CustomerNo), ChangeMustBeShownErr);
        ExpReportChangeLogEntries."Field Caption".AssertEquals(ExpenseReportLine.FieldCaption("Billable to Customer"));
        ExpReportChangeLogEntries."Old Value".AssertEquals('');
        ExpReportChangeLogEntries."User ID".AssertEquals(UpperCase(UserId()));
        ExpReportChangeLogEntries.Close();
        ExpenseReportPage.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ChangeHistoryActionOnPostedSubformShowsLineChanges()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        PostedExpenseReportPage: TestPage "Posted Expense Report";
        ExpReportChangeLogEntries: TestPage "Exp. Report Change Log Entries";
        ExpenseUserNo: Code[20];
        NewMerchantName: Text[100];
    begin
        // [SCENARIO 640772] The change history action on a line of the posted expense report shows the changes of that line.
        Initialize();

        // [GIVEN] Released expense report where the accountant changed "Merchant Name" of the line.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        ExpenseUserNo := ExpenseReportHeader."Expense User No.";
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        NewMerchantName := CopyStr(LibraryRandom.RandText(50), 1, MaxStrLen(NewMerchantName));
        ExpenseReportLine.Validate("Merchant Name", NewMerchantName);
        ExpenseReportLine.Modify(true);

        // [GIVEN] The expense report is posted.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUserNo);
        PostedExpenseReportHeader.FindFirst();

        // [WHEN] Open the change history from the line on the "Posted Expense Report" page.
        PostedExpenseReportPage.OpenView();
        PostedExpenseReportPage.GoToRecord(PostedExpenseReportHeader);
        PostedExpenseReportPage."Posted Expense Report Subform".First();
        ExpReportChangeLogEntries.Trap();
        PostedExpenseReportPage."Posted Expense Report Subform".ChangeHistory.Invoke();

        // [THEN] The change history is filtered to the line and shows the merchant change.
        Assert.AreEqual(Format(ExpenseReportLine."Line No."), ExpReportChangeLogEntries.Filter.GetFilter("Document Line No."), ChangeMustBeShownErr);
        Assert.IsTrue(ExpReportChangeLogEntries.FindFirstField("New Value", NewMerchantName), ChangeMustBeShownErr);
        ExpReportChangeLogEntries."Field Caption".AssertEquals(ExpenseReportLine.FieldCaption("Merchant Name"));
        ExpReportChangeLogEntries."User ID".AssertEquals(UpperCase(UserId()));
        ExpReportChangeLogEntries.Close();
        PostedExpenseReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AllTrackedLineFieldChangesAreLogged()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        OldExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO 640772] Changes to every tracked accounting field of a line on a released expense report are logged.
        Initialize();

        // [GIVEN] Released expense report with one line.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        OldExpenseReportLine := ExpenseReportLine;

        // [WHEN] Change the account, purchase invoice, vendor, project and VAT fields of the line.
        if ExpenseReportLine."Account Type" = ExpenseReportLine."Account Type"::Item then
            ExpenseReportLine."Account Type" := ExpenseReportLine."Account Type"::"G/L Account"
        else
            ExpenseReportLine."Account Type" := ExpenseReportLine."Account Type"::Item;
        ExpenseReportLine."Account No." := LibraryUtility.GenerateGUID();
        ExpenseReportLine."Purchase Invoice" := not ExpenseReportLine."Purchase Invoice";
        ExpenseReportLine."Vendor No." := LibraryUtility.GenerateGUID();
        ExpenseReportLine."Posted Purch. Invoice No." := LibraryUtility.GenerateGUID();
        ExpenseReportLine."Job No." := LibraryUtility.GenerateGUID();
        ExpenseReportLine."Job Task No." := LibraryUtility.GenerateGUID();
        ExpenseReportLine."VAT Liable" := not ExpenseReportLine."VAT Liable";
        ExpenseReportLine.Modify(true);

        // [THEN] Each change is logged with the old value, the new value and the user.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("Account Type"), Format(OldExpenseReportLine."Account Type"), Format(ExpenseReportLine."Account Type"));
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("Account No."), OldExpenseReportLine."Account No.", ExpenseReportLine."Account No.");
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("Purchase Invoice"), Format(OldExpenseReportLine."Purchase Invoice"), Format(ExpenseReportLine."Purchase Invoice"));
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("Vendor No."), OldExpenseReportLine."Vendor No.", ExpenseReportLine."Vendor No.");
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("Posted Purch. Invoice No."), OldExpenseReportLine."Posted Purch. Invoice No.", ExpenseReportLine."Posted Purch. Invoice No.");
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("Job No."), OldExpenseReportLine."Job No.", ExpenseReportLine."Job No.");
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("Job Task No."), OldExpenseReportLine."Job Task No.", ExpenseReportLine."Job Task No.");
        VerifyLineChangeLogEntry(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLine.FieldNo("VAT Liable"), Format(OldExpenseReportLine."VAT Liable"), Format(ExpenseReportLine."VAT Liable"));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ChangeHistoryActionOnSubformShowsLineChanges()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        ExpReportChangeLogEntries: TestPage "Exp. Report Change Log Entries";
        NewMerchantName: Text[100];
    begin
        // [SCENARIO 640772] The change history action on a line of the expense report shows the changes of that line.
        Initialize();

        // [GIVEN] Released expense report where the accountant changed "Merchant Name" of the line.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        NewMerchantName := ChangeMerchantName(ExpenseReportLine);

        // [WHEN] Open the change history from the line on the "Expense Report" page.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense Report Subform".First();
        ExpReportChangeLogEntries.Trap();
        ExpenseReportPage."Expense Report Subform".ChangeHistory.Invoke();

        // [THEN] The change history is filtered to the line and shows the merchant change.
        Assert.AreEqual(Format(ExpenseReportLine."Line No."), ExpReportChangeLogEntries.Filter.GetFilter("Document Line No."), ChangeMustBeShownErr);
        Assert.IsTrue(ExpReportChangeLogEntries.FindFirstField("New Value", NewMerchantName), ChangeMustBeShownErr);
        ExpReportChangeLogEntries."Field Caption".AssertEquals(ExpenseReportLine.FieldCaption("Merchant Name"));
        ExpReportChangeLogEntries.Close();
        ExpenseReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ChangeHistoryActionOnPostedReportShowsChanges()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportPage: TestPage "Posted Expense Report";
        ExpReportChangeLogEntries: TestPage "Exp. Report Change Log Entries";
        NewMerchantName: Text[100];
    begin
        // [SCENARIO 640772] The change history action on the posted expense report shows the changes made before posting.
        Initialize();

        // [GIVEN] Posted expense report where the accountant changed "Merchant Name" of the line before posting.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        NewMerchantName := ChangeMerchantName(ExpenseReportLine);
        PostExpenseReport(ExpenseReportHeader, PostedExpenseReportHeader);

        // [WHEN] Open the change history from the "Posted Expense Report" page.
        PostedExpenseReportPage.OpenView();
        PostedExpenseReportPage.GoToRecord(PostedExpenseReportHeader);
        ExpReportChangeLogEntries.Trap();
        PostedExpenseReportPage.ChangeHistory.Invoke();

        // [THEN] The change history shows the merchant change.
        Assert.IsTrue(ExpReportChangeLogEntries.FindFirstField("New Value", NewMerchantName), ChangeMustBeShownErr);
        ExpReportChangeLogEntries."Field Caption".AssertEquals(ExpenseReportLine.FieldCaption("Merchant Name"));
        ExpReportChangeLogEntries."User ID".AssertEquals(UpperCase(UserId()));
        ExpReportChangeLogEntries.Close();
        PostedExpenseReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ChangeHistoryActionOnManagerPageShowsChanges()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ManagerExpenseReportPage: TestPage "Manager Expense Report";
        ExpReportChangeLogEntries: TestPage "Exp. Report Change Log Entries";
        NewMerchantName: Text[100];
    begin
        // [SCENARIO 640772] The change history action on the "Manager Expense Report" page shows the changes made after submission.
        Initialize();

        // [GIVEN] Released expense report where the accountant changed "Merchant Name" of the line.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        NewMerchantName := ChangeMerchantName(ExpenseReportLine);

        // [WHEN] Open the change history from the "Manager Expense Report" page.
        ManagerExpenseReportPage.OpenView();
        ManagerExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpReportChangeLogEntries.Trap();
        ManagerExpenseReportPage.ChangeHistory.Invoke();

        // [THEN] The change history shows the merchant change.
        Assert.IsTrue(ExpReportChangeLogEntries.FindFirstField("New Value", NewMerchantName), ChangeMustBeShownErr);
        ExpReportChangeLogEntries."Field Caption".AssertEquals(ExpenseReportLine.FieldCaption("Merchant Name"));
        ExpReportChangeLogEntries.Close();
        ManagerExpenseReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure DeletingExpenseReportLineDeletesLineChangeHistory()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
        LineNo: Integer;
    begin
        // [SCENARIO 640772] The change history of an expense report line is deleted when the line is deleted.
        Initialize();

        // [GIVEN] Released expense report where the accountant changed "Merchant Name" of the line.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        LineNo := ExpenseReportLine."Line No.";
        ChangeMerchantName(ExpenseReportLine);
        ExpReportChangeLogEntry.SetRange("Source Table ID", Database::"Expense Report Header");
        ExpReportChangeLogEntry.SetRange("Source Record System ID", ExpenseReportHeader.SystemId);
        ExpReportChangeLogEntry.SetRange("Document Line No.", LineNo);
        Assert.RecordIsNotEmpty(ExpReportChangeLogEntry);

        // [WHEN] Delete the line.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", LineNo);
        ExpenseReportLine.Delete(true);

        // [THEN] The change history of the line is deleted.
        Assert.IsTrue(ExpReportChangeLogEntry.IsEmpty(), ChangeHistoryMustBeDeletedErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure DeletingExpenseReportDeletesChangeHistory()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
        ExpenseReportSystemId: Guid;
    begin
        // [SCENARIO 640772] The change history of an expense report is deleted when the expense report is deleted.
        Initialize();

        // [GIVEN] Released expense report with logged changes.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        ExpenseReportSystemId := ExpenseReportHeader.SystemId;
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        ChangeMerchantName(ExpenseReportLine);
        ExpReportChangeLogEntry.SetRange("Source Table ID", Database::"Expense Report Header");
        ExpReportChangeLogEntry.SetRange("Source Record System ID", ExpenseReportSystemId);
        Assert.RecordIsNotEmpty(ExpReportChangeLogEntry);

        // [WHEN] Delete the expense report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.Delete(true);

        // [THEN] The change history is deleted.
        Assert.IsTrue(ExpReportChangeLogEntry.IsEmpty(), ChangeHistoryMustBeDeletedErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure DeletingPostedExpenseReportDeletesChangeHistory()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
        PostedExpenseReportSystemId: Guid;
    begin
        // [SCENARIO 640772] The change history of a posted expense report is deleted when the posted expense report is deleted.
        Initialize();

        // [GIVEN] Posted expense report with logged changes.
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        ChangeMerchantName(ExpenseReportLine);
        PostExpenseReport(ExpenseReportHeader, PostedExpenseReportHeader);
        PostedExpenseReportSystemId := PostedExpenseReportHeader.SystemId;
        ExpReportChangeLogEntry.SetRange("Source Table ID", Database::"Posted Expense Report Header");
        ExpReportChangeLogEntry.SetRange("Source Record System ID", PostedExpenseReportSystemId);
        Assert.RecordIsNotEmpty(ExpReportChangeLogEntry);

        // [WHEN] Delete the posted expense report.
        PostedExpenseReportHeader.Delete(true);

        // [THEN] The change history is deleted.
        Assert.IsTrue(ExpReportChangeLogEntry.IsEmpty(), ChangeHistoryMustBeDeletedErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostingFailsWhenChangeOnReleasedReportCausesRuleViolation()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 640772] A change on a released expense report that violates the expense rules blocks posting, the same way it blocks release.
        Initialize();

        // [GIVEN] Released expense report with one line.
        CreateReleasedExpenseReport(ExpenseReportHeader);

        // [GIVEN] "Merchant Name" is mandatory in Expense Agent Setup.
        SetMerchantNameMandatory(true);

        // [GIVEN] The accountant clears "Merchant Name" on the line of the released expense report.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        ChangeMerchantName(ExpenseReportLine);
        ExpenseReportLine.Validate("Merchant Name", '');
        ExpenseReportLine.Modify(true);

        // [WHEN] Post the expense report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Posting fails because of the rule violation.
        Assert.ExpectedError(RuleViolationPresentOnLineErr);

        SetMerchantNameMandatory(false);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostingFailsWhenBillableLineHasNoCustomerAfterRelease()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 640772] A line made billable after release without a customer blocks posting, the same way it blocks release.
        Initialize();

        // [GIVEN] Released expense report where the line is made billable without "Billable to Customer".
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        ExpenseReportLine.Billable := true;
        ExpenseReportLine."Billable to Customer" := '';
        ExpenseReportLine.Modify(true);

        // [WHEN] Post the expense report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Posting fails because "Billable to Customer" must have a value.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Billable to Customer"), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostingFailsWhenPurchaseInvoiceLineHasNoVendorAfterRelease()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 640772] A line marked as purchase invoice after release without a vendor blocks posting, the same way it blocks release.
        Initialize();

        // [GIVEN] Released expense report where the line is marked as purchase invoice without "Vendor No.".
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        ExpenseReportLine."Purchase Invoice" := true;
        ExpenseReportLine."Vendor No." := '';
        ExpenseReportLine.Modify(true);

        // [WHEN] Post the expense report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Posting fails because "Vendor No." must have a value.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Vendor No."), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostingFailsWhenProjectLineHasNoProjectTaskAfterRelease()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 640772] A project set on a line after release without a project task blocks posting, the same way it blocks release.
        Initialize();

        // [GIVEN] Released expense report where the line gets a project without "Job Task No.".
        CreateReleasedExpenseReport(ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader);
        ExpenseReportLine."Job No." := LibraryUtility.GenerateGUID();
        ExpenseReportLine."Job Task No." := '';
        ExpenseReportLine.Modify(true);

        // [WHEN] Post the expense report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Posting fails because "Job Task No." must have a value.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Job Task No."), '');
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Exp. Report Change Log Test");
        LibraryVariableStorage.Clear();
        SetMerchantNameMandatory(false);
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Exp. Report Change Log Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryERMCountryData.UpdateLocalData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        Workflow.DeleteAll();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Exp. Report Change Log Test");
    end;

    local procedure CreateOpenExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    var
        Expense: Record Expense;
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpensePostingGroup: Record "Expense Posting Group";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseWithZeroVATPostingSetup(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandInt(100));

        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        ExpenseCategory.Get(Expense."Expense Category");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify();
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
    end;

    local procedure CreateReleasedExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    begin
        CreateOpenExpenseReport(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::Released);
    end;

    local procedure FindExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; ExpenseReportHeader: Record "Expense Report Header")
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.FindFirst();
    end;

    local procedure SetMerchantNameMandatory(MerchantNameMandatory: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        if ExpenseAgentSetup."Merchant Name Mandatory" = MerchantNameMandatory then
            exit;
        ExpenseAgentSetup.Validate("Merchant Name Mandatory", MerchantNameMandatory);
        ExpenseAgentSetup.Modify();
    end;

    local procedure ChangeMerchantName(var ExpenseReportLine: Record "Expense Report Line") NewMerchantName: Text[100]
    begin
        NewMerchantName := CopyStr(LibraryRandom.RandText(50), 1, MaxStrLen(NewMerchantName));
        ExpenseReportLine.Validate("Merchant Name", NewMerchantName);
        ExpenseReportLine.Modify(true);
    end;

    local procedure PostExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; var PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpenseUserNo: Code[20];
    begin
        ExpenseUserNo := ExpenseReportHeader."Expense User No.";
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUserNo);
        PostedExpenseReportHeader.FindFirst();
    end;

    local procedure FindChangeLogEntry(var ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry"; SourceTableID: Integer; SourceRecordSystemID: Guid; DocumentLineNo: Integer; TableID: Integer; FieldNo: Integer)
    begin
        ExpReportChangeLogEntry.Reset();
        ExpReportChangeLogEntry.SetRange("Source Table ID", SourceTableID);
        ExpReportChangeLogEntry.SetRange("Source Record System ID", SourceRecordSystemID);
        ExpReportChangeLogEntry.SetRange("Document Line No.", DocumentLineNo);
        if ExpReportChangeLogEntry.FindSet() then
            repeat
                if (ExpReportChangeLogEntry."Table ID" = TableID) and (ExpReportChangeLogEntry."Field No." = FieldNo) then
                    exit;
            until ExpReportChangeLogEntry.Next() = 0;

        Assert.Fail(StrSubstNo(ChangeLogEntryNotFoundErr, TableID, FieldNo, DocumentLineNo));
    end;

    local procedure VerifyLineChangeLogEntry(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; FieldNo: Integer; ExpectedOldValue: Text; ExpectedNewValue: Text)
    var
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
        RecordRef: RecordRef;
    begin
        FindChangeLogEntry(
            ExpReportChangeLogEntry, Database::"Expense Report Header", ExpenseReportHeader.SystemId, ExpenseReportLine."Line No.",
            Database::"Expense Report Line", FieldNo);

        RecordRef.GetTable(ExpenseReportLine);
        Assert.AreEqual(RecordRef.Field(FieldNo).Caption(), ExpReportChangeLogEntry."Field Caption", FieldCaptionMustBeLoggedErr);
        Assert.AreEqual(ExpectedOldValue, ExpReportChangeLogEntry."Old Value", OldValueMustBeLoggedErr);
        Assert.AreEqual(ExpectedNewValue, ExpReportChangeLogEntry."New Value", NewValueMustBeLoggedErr);
        Assert.AreEqual(ExpenseReportLine."Expense No.", ExpReportChangeLogEntry."Expense No.", ExpenseNoMustBeLoggedErr);
        VerifyChangeLogEntryAuditInfo(ExpReportChangeLogEntry);
    end;

    local procedure VerifyChangeLogEntryAuditInfo(ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry")
    var
        ExpectedUserID: Code[50];
    begin
        ExpectedUserID := CopyStr(UserId(), 1, MaxStrLen(ExpectedUserID));
        Assert.AreEqual(ExpectedUserID, ExpReportChangeLogEntry."User ID", UserMustBeLoggedErr);
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExpenseBillingInformationModalPageHandler(var ExpenseBillingInformation: TestPage "Expense Billing Information")
    begin
        ExpenseBillingInformation.Billable.SetValue(true);
        ExpenseBillingInformation."Billable to Customer".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseBillingInformation.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
