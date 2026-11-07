// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Sales.Customer;
using System;
using System.Automation;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 148303 "Expense Report Posting Test II"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryJob: Codeunit "Library - Job";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        JPEGLbl: Label '.jpeg';
        DocumentAttachmentDoesNotExistErr: Label 'Document Attachment does not exist on %1.', Comment = '%1 - Table Caption';
        DocumentAttachmentExistErr: Label 'Document Attachment exist on %1.', Comment = '%1 - Table Caption';
        ERLDocumentAttachmentMandatoryMsg: Label 'Document Attachment is mandatory on Expense Report No. %1 Line No. %2', Comment = '%1 = Expense Report No., %2 = Line No.';
        ExpenseReportLineAttachmentMissingMsg: Label 'Attachments are missing in Expense Report No. %1 Line No. %2.', Comment = '%1 = Expense Report No., %2 = Line No.';
        ReadyToPostQst: Label 'The number of expense reports that will be posted is %1. \Do you want to continue?', Comment = '%1 - selected count';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RuleViolationIsShownWhenAttachmentIsMandatoryInExpenseReport()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        DocumentAttachment: Record "Document Attachment";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        RecRef: RecordRef;
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 617011] Verify that Rule Violation is shown when Attachment is mandatory in Expense Category in Expense Report Line.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [GIVEN] Create Expense Report with Rule "Per Diem".
        CreateExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", "Expense Attachment Enforcement"::Error,
            '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that Rule Violation is shown on Expense Report due to Attachment is mandatory.
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(ERLDocumentAttachmentMandatoryMsg, ExpenseReportHeader."No.", ExpenseReportLine."Line No."));
        ExpenseReportPage.Close();

        // [GIVEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(ExpenseReportLine);
        CreateDocumentAttachment(DocumentAttachment, RecRef, ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No.") + JPEGLbl);

        // [WHEN] Open Expense Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that Document Attachment is shown on Expense Report.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportPage."Attached Documents List".Name.AssertEquals(ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No."));
        VerifyAttachmentExpenseReportLineFromWithoutExpense(ExpenseReportLine, true, DocumentAttachment.ID);

        // [THEN] Verify that No Rule Violation is shown on Expense Report after adding Attachment.
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage.Close();

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Attachment is posted on Posted Expense Report Line.
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseReportLine."Expense User No.");
        VerifyAttachmentPostedExpenseReportLineFromWithoutExpense(PostedExpenseReportLine, true, DocumentAttachment.ID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RuleViolationIsShownWhenAttachmentIsMandatoryInExpenseReportWithNoRule()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        DocumentAttachment: Record "Document Attachment";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        RecRef: RecordRef;
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 617011] Verify that Rule Violation is shown when Attachment is mandatory in Expense Category in Expense Report Line With No Rule.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [GIVEN] Create Expense Report with No Rule "Per Diem".
        CreateExpenseReportWithPerDiemNoRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, Amount, StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseReportLine."Reimbursement Type"::"Employee Paid", "Expense Attachment Enforcement"::Error, true);

        // [GIVEN] Create Per Diem for Expense Report Line.
        LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseReportLine."Expense Category", '', ExpenseReportLine."Expense Location", WorkDate(), true, true, true, Amount);

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that Rule Violation is shown on Expense Report due to Attachment is mandatory.
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(ERLDocumentAttachmentMandatoryMsg, ExpenseReportHeader."No.", ExpenseReportLine."Line No."));
        ExpenseReportPage.Close();

        // [GIVEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(ExpenseReportLine);
        CreateDocumentAttachment(DocumentAttachment, RecRef, ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No.") + JPEGLbl);

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that Document Attachment is shown on Expense Report.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportPage."Attached Documents List".Name.AssertEquals(ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No."));
        VerifyAttachmentExpenseReportLineFromWithoutExpense(ExpenseReportLine, true, DocumentAttachment.ID);

        // [THEN] Verify that No Rule Violation is shown on Expense Report after adding Attachment.
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage.Close();

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Attachment is posted on Posted Expense Report Line.
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseReportLine."Expense User No.");
        VerifyAttachmentPostedExpenseReportLineFromWithoutExpense(PostedExpenseReportLine, true, DocumentAttachment.ID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SentNotificationHandler')]
    procedure WarningIsShownWhenAttachmentEnforcementIsWarningInExpenseReport()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        DocumentAttachment: Record "Document Attachment";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        RecRef: RecordRef;
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 617011] Verify that Warning is shown when Attachment Enforcement is Warning in Expense Category in Expense Report Line.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [GIVEN] Create Expense Report with Rule "Per Diem".
        CreateExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", "Expense Attachment Enforcement"::Warning,
            '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that Rule Violation is not shown on Expense Report due to Attachment is Warning.
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        VerifyExpenseReportNotification(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportPage.Close();

        // [GIVEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(ExpenseReportLine);
        CreateDocumentAttachment(DocumentAttachment, RecRef, ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No.") + JPEGLbl);

        // [WHEN] Open Expense Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that Document Attachment is shown on Expense Report.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportPage."Attached Documents List".Name.AssertEquals(ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No."));
        VerifyAttachmentExpenseReportLineFromWithoutExpense(ExpenseReportLine, true, DocumentAttachment.ID);

        // [THEN] Verify that No Rule Violation is shown on Expense Report after adding Attachment.
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage.Close();

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Attachment is posted on Posted Expense Report Line.
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseReportLine."Expense User No.");
        VerifyAttachmentPostedExpenseReportLineFromWithoutExpense(PostedExpenseReportLine, true, DocumentAttachment.ID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SentNotificationHandler')]
    procedure WarningIsShownWhenAttachmentEnforcementIsWarningWithNoRuleInExpenseReport()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        DocumentAttachment: Record "Document Attachment";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        RecRef: RecordRef;
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 617011] Verify that Warning is shown when Attachment Enforcement is Warning in Expense CategoryWith No Rule.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [GIVEN] Create Expense Report with No Rule "Per Diem".
        CreateExpenseReportWithPerDiemNoRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, Amount, StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseReportLine."Reimbursement Type"::"Employee Paid", "Expense Attachment Enforcement"::Warning, true);

        // [GIVEN] Create Per Diem for Expense Report Line.
        LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseReportLine."Expense Category", '', ExpenseReportLine."Expense Location", WorkDate(), true, true, true, Amount);

        // [GIVEN] Apply Rule to Expense Report Line.
        ExpenseReportLine.ApplyRule();

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that Warning is shown on Expense Report due to Attachment is Warning.
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        VerifyExpenseReportNotification(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportPage.Close();

        // [GIVEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(ExpenseReportLine);
        CreateDocumentAttachment(DocumentAttachment, RecRef, ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No.") + JPEGLbl);

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that Document Attachment is shown on Expense Report.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportPage."Attached Documents List".Name.AssertEquals(ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No."));
        VerifyAttachmentExpenseReportLineFromWithoutExpense(ExpenseReportLine, true, DocumentAttachment.ID);

        // [THEN] Verify that No Rule Violation is shown on Expense Report after adding Attachment.
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage.Close();

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Attachment is posted on Posted Expense Report Line.
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseReportLine."Expense User No.");
        VerifyAttachmentPostedExpenseReportLineFromWithoutExpense(PostedExpenseReportLine, true, DocumentAttachment.ID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReceiptAttachedIsUpdatedWhenAttachmentIsDeletedFromExpenseReport()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        DocumentAttachment: Record "Document Attachment";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        RecRef: RecordRef;
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 617011] Verify that Receipt Attached is updated when Attachment is deleted from Expense Report Line.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", "Expense Attachment Enforcement"::" ",
            '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(ExpenseReportLine);
        CreateDocumentAttachment(DocumentAttachment, RecRef, ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No.") + JPEGLbl);

        // [WHEN] Open Expense Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that Document Attachment is shown on Expense Report.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportPage."Attached Documents List".Name.AssertEquals(ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No."));
        Assert.AreEqual(
            true,
            ExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Attached"), true, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            DocumentAttachment.ID,
            ExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Entry"), DocumentAttachment.ID, ExpenseReportLine.TableCaption()));

        // [WHEN] Delete Attachment from Expense Report Line.
        DocumentAttachment.Delete(true);

        // [THEN] Verify that Attachment is deleted from Expense Report Line.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(
            false,
            ExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Attached"), false, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            0,
            ExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Entry"), 0, ExpenseReportLine.TableCaption()));

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Attachment is posted on Posted Expense Report Line.
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseReportLine."Expense User No.");
        Assert.AreEqual(
            false,
            PostedExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Receipt Attached"), false, PostedExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            0,
            PostedExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Receipt Entry"), 0, PostedExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReceiptAttachedIsUpdatedWhenAttachmentIsDeletedFromExpenseReportWithNoRule()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        DocumentAttachment: Record "Document Attachment";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        RecRef: RecordRef;
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 617011] Verify that Receipt Attached is updated when Attachment is deleted from Expense Report Line With No Rule.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [GIVEN] Create Expense Report with No Rule "Per Diem".
        CreateExpenseReportWithPerDiemNoRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, Amount, StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseReportLine."Reimbursement Type"::"Employee Paid", "Expense Attachment Enforcement"::" ", true);

        // [GIVEN] Create Per Diem for Expense Report Line.
        LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseReportLine."Expense Category", '', ExpenseReportLine."Expense Location", WorkDate(), true, true, true, Amount);

        // [GIVEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(ExpenseReportLine);
        CreateDocumentAttachment(DocumentAttachment, RecRef, ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No.") + JPEGLbl);

        // [WHEN] Open Expense Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that Document Attachment is shown on Expense Report.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportPage."Attached Documents List".Name.AssertEquals(ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No."));
        Assert.AreEqual(
            true,
            ExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Attached"), true, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            DocumentAttachment.ID,
            ExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Entry"), DocumentAttachment.ID, ExpenseReportLine.TableCaption()));

        // [WHEN] Delete Attachment from Expense Report Line.
        DocumentAttachment.Delete(true);

        // [THEN] Verify that Attachment is deleted from Expense Report Line.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(
            false,
            ExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Attached"), false, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            0,
            ExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Entry"), 0, ExpenseReportLine.TableCaption()));

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Attachment is posted on Posted Expense Report Line.
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseReportLine."Expense User No.");
        Assert.AreEqual(
            false,
            PostedExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Receipt Attached"), false, PostedExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            0,
            PostedExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Receipt Entry"), 0, PostedExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure UnitCostIsUpdatedInJobLedgerEntryWhenExpenseReportIsPostedWithJob()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 617017] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create and Post Expense Report with Job.
        CreateAndPostExpenseReportWithJob(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, ExpenseReportHeader, "Expense Reimbursement Type"::"Company Paid", CurrencyCode, CurrencyCode, Amount);

        // [THEN] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyJobLedgerEntry(
            PostedExpenseReportHeader,
            PostedExpenseReportLine,
            GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"),
            CurrencyCode,
            Amount,
            ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ExpenseBillingInformationModalPageErrorHandler,ConfirmHandler,PostedExpenseReportModalPageHandler')]
    procedure ReceiptNoAndMerchantNameIsRequiredWhenEnableInExpenseAgentSetup()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        UnitOfMeasure: Record "Unit of Measure";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO 616955] Verify that Receipt No and Merchant Name are required when enabled in Expense Agent Setup.
        // [SCENARIO 641894] Verify Receipt No is not mandatory When Expense Category is Mileage and "Receipt No. Mandatory" is enabled in Expense Agent Setup.
        // [SCENARIO 641894] Verify Merchant Name is not mandatory When Expense Category is Mileage and "Merchant Name Mandatory" is enabled in Expense Agent Setup.
        Initialize();

        // [GIVEN] Create Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Validate("Default Mileage UOM", UnitOfMeasure.Code);
        ExpenseAgentSetup.Validate("Receipt No. Mandatory", true);
        ExpenseAgentSetup.Validate("Merchant Name Mandatory", true);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Mileage, ExpensePaymentMethod.Code);

        // [GIVEN] Update Expense Account in Employee Posting Group.
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, ExpenseCategory.Code, ExpenseUser."No.");

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Mileage.SetValue(LibraryRandom.RandDec(100, 2));

        // [THEN] Verify that Rule Violation is not created in Expense Report Line for "Merchant Name" and "Receipt No.".
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportRuleViolation, 0);

        // [WHEN] Open Expense Billing Information Page.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandText(20));
        LibraryVariableStorage.Enqueue(LibraryRandom.RandText(20));
        ExpenseReportPage."Expense Report Subform"."Show Billable Information".Invoke();

        // [THEN] Verify that Merchant Name errors are cleared after filling in the values.
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');

        // [WHEN] Post Expense Report.
        FindExpenseReportLine(ExpenseReportLine, CopyStr(ExpenseReportPage."No.".Value(), 1, 20));
        ExpenseReportPage.Post.Invoke();

        // [THEN] Verify that Expense Report is posted successfully.
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseReportLine."Expense User No.");
        Assert.AreEqual(
            ExpenseReportLine."Merchant Name",
            PostedExpenseReportLine."Merchant Name",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Merchant Name"), ExpenseReportLine."Merchant Name", PostedExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLine."Expense Ext. Doc. No.",
            PostedExpenseReportLine."Expense Ext. Doc. No.",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Expense Ext. Doc. No."), ExpenseReportLine."Expense Ext. Doc. No.", PostedExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure DimensionSetIDMustBeCopiedFromExpenseInExpenseReport()
    var
        DefaultDimension: array[5] of Record "Default Dimension";
        DimensionValue: array[4] of Record "Dimension Value";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense SubCategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        Expense: Record Expense;
        Customer: Record Customer;
        PostCode: Record "Post Code";
        JobTask: Record "Job Task";
    begin
        // [SCENARIO 617034] Verify that the Dimension Set ID is copied from Expense in Expense Report.
        Initialize();

        // [GIVEN] Update "Receipt No. Mandatory" and "Merchant Name Mandatory" in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Receipt No. Mandatory", false);
        ExpenseAgentSetup.Validate("Merchant Name Mandatory", false);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Global Dimension Value 1 and 2.
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);

        // [GIVEN] Create Dimension Value 3 and 4.
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Delete Default Dimension for Customer.
        DefaultDimension[3].SetRange("Table Id", Database::Customer);
        DefaultDimension[3].SetRange("No.", Customer."No.");
        DefaultDimension[3].DeleteAll();

        // [GIVEN] Set Dimension Value 3 as Default Dimension for Customer.
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension[1], Customer."No.", DimensionValue[3]."Dimension Code", DimensionValue[3].Code);

        // [GIVEN] Create Job with Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Delete Default Dimension for Job.
        DefaultDimension[3].SetRange("Table Id", Database::Job);
        DefaultDimension[3].SetFilter("No.", '%1|%2', JobTask."Job No.", '');
        DefaultDimension[3].DeleteAll();

        // [GIVEN] Set Dimension Value 4 as Default Dimension for Job.
        LibraryDimension.CreateDefaultDimension(DefaultDimension[2], Database::Job, JobTask."Job No.", DimensionValue[4]."Dimension Code", DimensionValue[4].Code);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Set Dimension Value 1 and 2 as Default Dimension for Expense User.
        LibraryDimension.CreateDefaultDimension(DefaultDimension[4], Database::Employee, ExpenseUser."Employee No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension[4], Database::Employee, ExpenseUser."Employee No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // [GIVEN] Create Expense Category with Itemize requirement.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Itemize);

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.Validate("Job No.", JobTask."Job No.");
        Expense.Validate("Job Task No.", JobTask."Job Task No.");
        Expense.Modify();

        // [GIVEN] Release Expense.
        Expense.PerformManualRelease();

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '');

        // [THEN] Verify that the Dimension Set ID is copied from Expense in Expense Report.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        Assert.AreEqual(
            Expense."Dimension Set ID",
            ExpenseReportLine."Dimension Set ID",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Dimension Set ID"), Expense."Dimension Set ID", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure DimensionMustBeCopyFromEmployeeCustomerAndJobInExpense()
    var
        DefaultDimension: array[5] of Record "Default Dimension";
        DimensionValue: array[4] of Record "Dimension Value";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense SubCategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        Customer: Record Customer;
        PostCode: Record "Post Code";
        JobTask: Record "Job Task";
    begin
        // [SCENARIO 617034] Verify that the Dimension is copied from Employee, Customer and Job in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Global Dimension Value 1 and 2.
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);

        // [GIVEN] Create Dimension Value 3 and 4.
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Delete Default Dimension for Customer.
        DefaultDimension[3].SetRange("Table Id", Database::Customer);
        DefaultDimension[3].SetRange("No.", Customer."No.");
        DefaultDimension[3].DeleteAll();

        // [GIVEN] Set Dimension Value 3 as Default Dimension for Customer.
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension[1], Customer."No.", DimensionValue[3]."Dimension Code", DimensionValue[3].Code);

        // [GIVEN] Create Job with Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Delete Default Dimension for Job.
        DefaultDimension[3].SetRange("Table Id", Database::Job);
        DefaultDimension[3].SetFilter("No.", '%1|%2', JobTask."Job No.", '');
        DefaultDimension[3].DeleteAll();

        // [GIVEN] Set Dimension Value 4 as Default Dimension for Job.
        LibraryDimension.CreateDefaultDimension(DefaultDimension[2], Database::Job, JobTask."Job No.", DimensionValue[4]."Dimension Code", DimensionValue[4].Code);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Set Dimension Value 1 and 2 as Default Dimension for Expense User.
        LibraryDimension.CreateDefaultDimension(DefaultDimension[4], Database::Employee, ExpenseUser."Employee No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension[4], Database::Employee, ExpenseUser."Employee No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // [GIVEN] Create Expense Category with Itemize requirement.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Itemize);

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [WHEN] Create Expense Report with Line.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', LibraryRandom.RandIntInRange(100, 200));

        // [THEN] Verify that the Dimension is copied from Employee.
        VerifyDimensionFromDimensionSetID(ExpenseReportHeader."Dimension Set ID", 2, DimensionValue[1]);
        VerifyDimensionFromDimensionSetID(ExpenseReportHeader."Dimension Set ID", 2, DimensionValue[2]);
        VerifyDimensionFromDimensionSetID(ExpenseReportLine."Dimension Set ID", 2, DimensionValue[1]);
        VerifyDimensionFromDimensionSetID(ExpenseReportLine."Dimension Set ID", 2, DimensionValue[2]);

        // [WHEN] Update Expense Report Line with Job.
        ExpenseReportLine.Validate("Job No.", JobTask."Job No.");
        ExpenseReportLine.Validate("Job Task No.", JobTask."Job Task No.");

        // [THEN] Verify that the "Dimension Set ID" is updated in  Expense Report Line.
        VerifyDimensionFromDimensionSetID(ExpenseReportHeader."Dimension Set ID", 2, DimensionValue[1]);
        VerifyDimensionFromDimensionSetID(ExpenseReportHeader."Dimension Set ID", 2, DimensionValue[2]);
        VerifyDimensionFromDimensionSetID(ExpenseReportLine."Dimension Set ID", 3, DimensionValue[1]);
        VerifyDimensionFromDimensionSetID(ExpenseReportLine."Dimension Set ID", 3, DimensionValue[2]);
        VerifyDimensionFromDimensionSetID(ExpenseReportLine."Dimension Set ID", 3, DimensionValue[4]);

        // [WHEN] Update Expense Report Line with Billable to Customer.
        ExpenseReportLine.Validate("Job No.", '');
        ExpenseReportLine.Validate(Billable, true);
        ExpenseReportLine.Validate("Billable to Customer", Customer."No.");
        ExpenseReportLine.Modify();

        // [THEN] Verify that the "Dimension Set ID" is updated in Expense Report Line.
        VerifyDimensionFromDimensionSetID(ExpenseReportHeader."Dimension Set ID", 2, DimensionValue[1]);
        VerifyDimensionFromDimensionSetID(ExpenseReportHeader."Dimension Set ID", 2, DimensionValue[2]);
        VerifyDimensionFromDimensionSetID(ExpenseReportLine."Dimension Set ID", 3, DimensionValue[1]);
        VerifyDimensionFromDimensionSetID(ExpenseReportLine."Dimension Set ID", 3, DimensionValue[2]);
        VerifyDimensionFromDimensionSetID(ExpenseReportLine."Dimension Set ID", 3, DimensionValue[3]);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure UnitCostIsUpdatedInJobLedgerEntryWhenExpenseReportIsPostedWithJobWithLCYAndFCYInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 620126] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job.
        // When LCY is used as Currency Code in Job and FCY is used as Currency Code in Expense.
        Initialize();

        // [GIVEN] Update "Receipt No. Mandatory" and "Merchant Name Mandatory" in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Receipt No. Mandatory", false);
        ExpenseAgentSetup.Validate("Merchant Name Mandatory", false);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create and Post Expense Report with Job.
        CreateAndPostExpenseReportWithJob(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, ExpenseReportHeader, "Expense Reimbursement Type"::"Employee Paid", CurrencyCode, '', Amount);

        // [THEN] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job with LCY.
        VerifyPostedExpenseReportWithJob(Expense, ExpenseUser, '', ExpectedAmountLCY, ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure UnitCostIsUpdatedInJobLedgerEntryWhenExpenseReportIsPostedWithJobWithFCYAndFCYInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 620126] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job.
        // When FCY is used as Currency Code in Job and FCY is used as Currency Code in Expense.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create and Post Expense Report with Job.
        CreateAndPostExpenseReportWithJob(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, ExpenseReportHeader, "Expense Reimbursement Type"::"Employee Paid", CurrencyCode, CurrencyCode, Amount);

        // [THEN] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job with FCY.
        VerifyPostedExpenseReportWithJob(Expense, ExpenseUser, CurrencyCode, Amount, ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure UnitCostIsUpdatedInJobLedgerEntryWhenExpenseReportIsPostedWithJobWithLCYAndLCYInExpense()
    var
        Expense: Record Expense;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        Amount: Decimal;
    begin
        // [SCENARIO 620126] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job.
        // When LCY is used as Currency Code in Job and LCY is used as Currency Code in Expense.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [WHEN] Create and Post Expense Report with Job.
        CreateAndPostExpenseReportWithJob(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, ExpenseReportHeader, "Expense Reimbursement Type"::"Employee Paid", '', '', Amount);

        // [THEN] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job with LCY.
        VerifyPostedExpenseReportWithJob(Expense, ExpenseUser, '', Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure UnitCostIsUpdatedInJobLedgerEntryWhenExpenseReportIsPostedWithJobWithFCYAndLCYInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        Amount: Decimal;
        ExpectedAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 620126] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job.
        // When FCY is used as Currency Code in Job and LCY is used as Currency Code in Expense.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountFCY := Round(LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create and Post Expense Report with Job.
        CreateAndPostExpenseReportWithJob(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, ExpenseReportHeader, "Expense Reimbursement Type"::"Employee Paid", '', CurrencyCode, Amount);

        // [THEN] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job with LCY.
        VerifyPostedExpenseReportWithJob(Expense, ExpenseUser, CurrencyCode, ExpectedAmountFCY, Amount);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure UnitCostIsUpdatedInJobLedgerEntryWhenExpenseReportIsPostedWithJobWithDifferentFCYAndFCYInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        JobCurrency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        JobAmount: Decimal;
        ExpenseCurrencyCode: Code[10];
        JobCurrencyCode: Code[10];
    begin
        // [SCENARIO 620126] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job.
        // When FCY is used as Different Currency Code in Job and FCY is used as Currency Code in Expense.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        ExpenseCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        JobCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(ExpenseCurrencyCode);
        JobCurrency.Get(JobCurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, ExpenseCurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");
        JobAmount := Round(LibraryERM.ConvertCurrency(ExpectedAmountLCY, '', JobCurrencyCode, WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create and Post Expense Report with Job.
        CreateAndPostExpenseReportWithJob(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, ExpenseReportHeader, "Expense Reimbursement Type"::"Employee Paid", ExpenseCurrencyCode, JobCurrencyCode, Amount);

        // [THEN] Verify that Unit Cost is updated in Job Ledger Entry when Expense Report is posted with Job with FCY.
        VerifyPostedExpenseReportWithJob(Expense, ExpenseUser, JobCurrencyCode, JobAmount, ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PostedExpenseReportModalPageHandler')]
    procedure ExpenseReportCanBePostedWithMileageWithTwoDecimalPlaces()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        UnitOfMeasure: Record "Unit of Measure";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 634224] Verify that Expense Report can be posted with Mileage with two decimal places.
        Initialize();

        // [GIVEN] Create Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", 4.32);
        ExpenseAgentSetup.Validate("Default Mileage UOM", UnitOfMeasure.Code);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Mileage, ExpensePaymentMethod.Code);

        // [GIVEN] Update Expense Account in Employee Posting Group.
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, ExpenseCategory.Code, ExpenseUser."No.");

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Mileage.SetValue(LibraryRandom.RandDec(100, 2));

        // [WHEN] Post Expense Report.
        FindExpenseReportLine(ExpenseReportLine, CopyStr(ExpenseReportPage."No.".Value(), 1, 20));
        ExpenseReportPage.Post.Invoke();

        // [THEN] Verify that Expense Report is posted successfully.
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseReportLine."Expense User No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure MultipleExpenseReportsArePostedWhenBatchPosting()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        Employee: Record Employee;
        Expense: array[2] of Record Expense;
        ExpenseReportHeader: array[2] of Record "Expense Report Header";
        ExpenseReportHeaderToPost: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportBatchPostMgt: Codeunit "Expense Report Batch Post Mgt.";
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        // [SCENARIO 641880] Verify that multiple Expense Reports are posted when batch posting.
        Initialize();

        // [GIVEN] An Expense User with an updated Employee Posting Group.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Two released Expense Reports for the same Expense User.
        CreateReleasedExpenseReport(ExpenseReportHeader[1], Expense[1], ExpenseCategory, ExpenseUser);
        CreateReleasedExpenseReport(ExpenseReportHeader[2], Expense[2], ExpenseCategory, ExpenseUser);
        Commit();

        // [WHEN] Batch post the selected Expense Reports.
        ExpenseReportHeaderToPost.SetFilter("No.", '%1|%2', ExpenseReportHeader[1]."No.", ExpenseReportHeader[2]."No.");
        BatchProcessingMgt.SetParametersForPageID(Page::"Expense Reports");
        ExpenseReportBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        ExpenseReportBatchPostMgt.RunWithUI(ExpenseReportHeaderToPost, ExpenseReportHeaderToPost.Count, ReadyToPostQst);

        // [THEN] Both Expense Reports are posted.
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordCount(PostedExpenseReportHeader, 2);

        // [THEN] The Expense Reports no longer exist as open documents.
        Assert.IsFalse(ExpenseReportHeader[1].Find(), 'First Expense Report should have been posted and removed.');
        Assert.IsFalse(ExpenseReportHeader[2].Find(), 'Second Expense Report should have been posted and removed.');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmNoHandler')]
    procedure NoExpenseReportsArePostedWhenBatchPostingIsNotConfirmed()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        Employee: Record Employee;
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportHeaderToPost: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportBatchPostMgt: Codeunit "Expense Report Batch Post Mgt.";
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        // [SCENARIO 641880] Verify that no Expense Reports are posted when the batch posting confirmation is declined.
        Initialize();

        // [GIVEN] An Expense User with an updated Employee Posting Group.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] A released Expense Report.
        CreateReleasedExpenseReport(ExpenseReportHeader, Expense, ExpenseCategory, ExpenseUser);
        Commit();

        // [WHEN] Batch post is invoked but the confirmation is declined.
        ExpenseReportHeaderToPost.SetRange("No.", ExpenseReportHeader."No.");
        BatchProcessingMgt.SetParametersForPageID(Page::"Expense Reports");
        ExpenseReportBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        ExpenseReportBatchPostMgt.RunWithUI(ExpenseReportHeaderToPost, ExpenseReportHeaderToPost.Count, ReadyToPostQst);

        // [THEN] No Posted Expense Report is created.
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordIsEmpty(PostedExpenseReportHeader);

        // [THEN] The Expense Report still exists as an open document.
        Assert.IsFalse(ExpenseReportHeader.IsEmpty(), 'Expense Report should not have been posted.');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,MessageHandler')]
    procedure ExpenseReportIsPostedWhenBatchPostingSingleReport()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        Employee: Record Employee;
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportBatchPostMgt: Codeunit "Expense Report Batch Post Mgt.";
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        // [SCENARIO 641880] Verify that a single Expense Report is posted through the batch post management Code procedure.
        Initialize();

        // [GIVEN] An Expense User with an updated Employee Posting Group.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] A released Expense Report.
        CreateReleasedExpenseReport(ExpenseReportHeader, Expense, ExpenseCategory, ExpenseUser);
        Commit();

        // [WHEN] Batch process the Expense Report using the configured batch processor.
        ExpenseReportHeader.SetRecFilter();
        ExpenseReportBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        ExpenseReportBatchPostMgt.SetPostingCodeunitId(Codeunit::"Expense Report-Post");
        ExpenseReportBatchPostMgt.Code(ExpenseReportHeader);

        // [THEN] The Expense Report is posted.
        // [THEN] No batch confirmation dialog is shown because a single Expense Report is posted directly.
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordCount(PostedExpenseReportHeader, 1);
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        ExpensePostingGroup: Record "Expense Posting Group";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Report Posting Test II");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Report Posting Test II");
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

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Report Posting Test II");
    end;

    local procedure CreateExpenseReportWithPerDiemRule(
        var ExpenseReportHeader: Record "Expense Report Header";
        var ExpenseReportLine: Record "Expense Report Line";
        var ExpenseUser: Record "Expense User";
        var ExpenseRuleHeader: Record "Expense Rule Header";
        var ExpenseRuleCondition: Record "Expense Rule Condition";
        CountryRegionCode: Code[10];
        City: Text[30];
        CurrencyCode: Code[10];
        Amount: Decimal;
        EffectiveDate: Date;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
        ExpenseDetailRequired: Enum "Expense Detail Needed";
        JustificationRequired: Enum "Expense Justification";
        ReimbursementType: Enum "Expense Reimbursement Type";
        AttachmentEnforcement: Enum "Expense Attachment Enforcement";
        UnitOfMeasureCode: Code[10];
        ConditionType: Enum "Expense Rule Condition Type";
        Refundable: Boolean;
        Value: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ReimbursementType, ExpenseDetailRequired);

        UpdateAttachmentEnforcementInExpenseCategory(ExpenseCategory.Code, AttachmentEnforcement);

        LibraryExpense.CreateExpenseLocation(ExpenseLocation, CountryRegionCode, City);
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", EffectiveDate,
            JustificationRequired, CurrencyCode, UnitOfMeasureCode, ConditionType, Value);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, CurrencyCode, Amount);
        ExpenseReportLine.Validate("Expense Location", ExpenseLocation."No.");
        ExpenseReportLine.Validate(Refundable, Refundable);
        ExpenseReportLine.Validate("Starting Date and Time", StartingDateTime);
        ExpenseReportLine.Validate("Ending Date and Time", EndingDateTime);
        ExpenseReportLine.Modify();

        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, ExpenseCategory.Code, ExpenseUser."No.");
    end;

    local procedure CreateExpenseReportWithPerDiemNoRule(
        var ExpenseReportHeader: Record "Expense Report Header";
        var ExpenseReportLine: Record "Expense Report Line";
        var ExpenseUser: Record "Expense User";
        CountryRegionCode: Code[10];
        City: Text[30];
        CurrencyCode: Code[10];
        Amount: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
        ExpenseDetailRequired: Enum "Expense Detail Needed";
        ReimbursementType: Enum "Expense Reimbursement Type";
        AttachmentEnforcement: Enum "Expense Attachment Enforcement";
        Refundable: Boolean)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ReimbursementType, ExpenseDetailRequired);

        UpdateAttachmentEnforcementInExpenseCategory(ExpenseCategory.Code, AttachmentEnforcement);

        LibraryExpense.CreateExpenseLocation(ExpenseLocation, CountryRegionCode, City);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, CurrencyCode, Amount);
        ExpenseReportLine.Validate("Expense Location", ExpenseLocation."No.");
        ExpenseReportLine.Validate(Refundable, Refundable);
        ExpenseReportLine.Validate("Starting Date and Time", StartingDateTime);
        ExpenseReportLine.Validate("Ending Date and Time", EndingDateTime);
        ExpenseReportLine.Modify();

        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, ExpenseCategory.Code, ExpenseUser."No.");
    end;

    local procedure CreateAndReleaseExpenseWithJobTask(var Expense: Record Expense; var ExpenseUser: Record "Expense User"; var ExpensePaymentMethod: Record "Expense Payment Method"; var JobTask: Record "Job Task"; ReimbursementType: Enum "Expense Reimbursement Type"; Refundable: Boolean; CurrencyCode: Code[10]; JobCurrencyCode: Code[10]; AmountReduction: Decimal; Amount: Decimal)
    var
        Job: Record Job;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ReimbursementType);

        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        Job.Validate("Currency Code", JobCurrencyCode);
        Job.Modify();

        CreateExpense(Expense, Refundable, CurrencyCode, Amount);
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Validate("Non-Refundable Amount", AmountReduction);
        Expense.Validate("Job No.", JobTask."Job No.");
        Expense.Validate("Job Task No.", JobTask."Job Task No.");
        Expense.Modify();

        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
    end;

    local procedure CreateExpense(var Expense: Record Expense; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', Refundable, CurrencyCode, Amount);
    end;

    local procedure UpdateExpenseAccountInEmployeePostingGroup(var ExpenseUser: Record "Expense User"; Expense: Record "Expense")
    var
        ExpenseCategory: Record "Expense Category";
        Employee: Record Employee;
    begin
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseUser.Get(Expense."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");

        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateReleasedExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; var Expense: Record Expense; ExpenseCategory: Record "Expense Category"; ExpenseUser: Record "Expense User")
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseSubCategory: Record "Expense Subcategory";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseWithZeroVATPostingSetup(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandInt(100));
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpenseCategory."Reimbursement Type");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();
    end;

    local procedure UpdateAttachmentEnforcementInExpenseCategory(CategoryCode: Code[20]; AttachmentEnforcement: Enum "Expense Attachment Enforcement")
    var
        ExpenseCategory: Record "Expense Category";
    begin
        ExpenseCategory.Get(CategoryCode);
        ExpenseCategory.Validate("Attachment Enforcement", AttachmentEnforcement);
        ExpenseCategory.Modify(true);
    end;

    local procedure CreateAndAttachExpenseToExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20]; CurrencyCode: Code[10])
    var
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUserNo, CurrencyCode, '');
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
    end;

    local procedure UpdateExpenseAccountInEmployeePostingGroup(var ExpenseUser: Record "Expense User"; CategoryCode: Code[20]; ExpenseUserNo: Code[20])
    var
        ExpenseCategory: Record "Expense Category";
        Employee: Record Employee;
    begin
        ExpenseCategory.Get(CategoryCode);
        ExpenseUser.Get(ExpenseUserNo);
        Employee.Get(ExpenseUser."Employee No.");

        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
    end;

    local procedure CreateDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        DocumentAttachment.Init();
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
    end;

    local procedure CreateTempBLOBWithImageOfType(var TempBlob: Codeunit "Temp Blob"; ImageType: Text)
    var
        ImageFormat: DotNet ImageFormat;
        Bitmap: DotNet Bitmap;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        Bitmap := Bitmap.Bitmap(1, 1);
        case ImageType of
            'png':
                Bitmap.Save(InStr, ImageFormat.Png);
            'jpeg':
                Bitmap.Save(InStr, ImageFormat.Jpeg);
            else
                Bitmap.Save(InStr, ImageFormat.Bmp);
        end;
        Bitmap.Dispose();
    end;

    local procedure CheckIfDocAttachExist(TableNo: Integer; DocNo: Code[20]; LineNo: Integer): Boolean;
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", TableNo);
        DocumentAttachment.SetRange("No.", DocNo);
        if LineNo <> 0 then
            DocumentAttachment.SetRange("Line No.", LineNo);

        exit(not DocumentAttachment.IsEmpty())
    end;

    local procedure FindExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; ExpenseReportNo: Code[20])
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportNo);
        ExpenseReportLine.FindFirst();
    end;

    local procedure FindPostedExpenseReportLine(var PostedExpenseReportLine: Record "Posted Expense Report Line"; ExpenseUserNo: Code[20])
    begin
        PostedExpenseReportLine.SetRange("Expense User No.", ExpenseUserNo);
        PostedExpenseReportLine.FindFirst();
    end;

    local procedure FindExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; Expense: Record Expense)
    begin
        ExpenseReportLine.SetRange("Expense No.", Expense."No.");
        ExpenseReportLine.FindFirst();
    end;

    local procedure VerifyAttachmentExpenseReportLineFromWithoutExpense(ExpenseReportLine: Record "Expense Report Line"; ReceiptAttached: Boolean; ReceiptId: Integer)
    var
        Expense: Record Expense;
    begin
        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::"Expense Report Line", ExpenseReportLine."Document No.", ExpenseReportLine."Line No."),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            false,
            CheckIfDocAttachExist(Database::Expense, ExpenseReportLine."Document No.", 0),
            StrSubstNo(DocumentAttachmentExistErr, Expense.TableCaption()));
        Assert.AreEqual(
            ReceiptAttached,
            ExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Attached"), ReceiptAttached, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ReceiptId,
            ExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Entry"), ReceiptId, ExpenseReportLine.TableCaption()));
    end;

    local procedure VerifyAttachmentPostedExpenseReportLineFromWithoutExpense(PostedExpenseReportLine: Record "Posted Expense Report Line"; ReceiptAttached: Boolean; ReceiptId: Integer)
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::"Posted Expense Report Line", PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No."),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, PostedExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            false,
            CheckIfDocAttachExist(Database::"Expense Report Line", PostedExpenseReportLine."Document No.", 0),
            StrSubstNo(DocumentAttachmentExistErr, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ReceiptAttached,
            PostedExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Receipt Attached"), ReceiptAttached, PostedExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ReceiptId,
            PostedExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Receipt Entry"), ReceiptId, PostedExpenseReportLine.TableCaption()));
    end;

    local procedure VerifyExpenseReportNotification(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer)
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.Get(ExpenseReportNo, ExpenseReportLineNo);

        Assert.ExpectedMessage(StrSubstNo(ExpenseReportLineAttachmentMissingMsg, ExpenseReportLine."Document No.", ExpenseReportLine."Line No."), LibraryVariableStorage.DequeueText()); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty();
        Clear(ExpenseReportLine);
        LibraryNotificationMgt.RecallNotificationsForRecord(ExpenseReportLine);
    end;

    local procedure FindPostedExpenseReport(var PostedExpenseReportHeader: Record "Posted Expense Report Header"; Expense: Record Expense)
    begin
        PostedExpenseReportHeader.SetRange("Expense User No.", Expense."Expense User No.");
        PostedExpenseReportHeader.FindFirst();
    end;

    local procedure FindPostedExpenseReportLine(var PostedExpenseReportLine: Record "Posted Expense Report Line"; Expense: Record Expense)
    begin
        PostedExpenseReportLine.SetRange("Expense No.", Expense."No.");
        PostedExpenseReportLine.FindFirst();
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; AccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.CalcSums(Amount);

        Assert.AreEqual(
            ExpectedAmount,
            GLEntry.Amount,
            StrSubstNo(ValueMustBeEqualErr, GLEntry.FieldCaption(Amount), ExpectedAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyRecordCountOfEmployeeLedgerEntry(DocumentNo: Code[20]; ExpectedRecordCount: Integer)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(EmployeeLedgerEntry, ExpectedRecordCount);
    end;

    local procedure GetRefundableDebitAccountFromExpensePostingGroup(ExpenseCategoryCode: Code[20]): Code[20]
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        ExpenseCategory.Get(ExpenseCategoryCode);
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        exit(ExpensePostingGroup."Refundable Debit Account");
    end;

    local procedure VerifyExpenseLedgerEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line"; Expense: Record Expense)
    var
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
#pragma warning disable AA0210
        ExpenseLedgerEntry.SetRange("Document Type", ExpenseLedgerEntry."Document Type"::Invoice);
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        ExpenseLedgerEntry.SetRange("Document Line No.", PostedExpenseReportLine."Line No.");
#pragma warning restore AA0210
        ExpenseLedgerEntry.FindFirst();
        Assert.RecordCount(ExpenseLedgerEntry, 1);

        ExpenseCategory.Get(PostedExpenseReportLine."Expense Category");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        Assert.AreEqual(
            Expense."Job No.",
            ExpenseLedgerEntry."Job No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Job No."), Expense."Job No.", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            Expense."Job Task No.",
            ExpenseLedgerEntry."Job Task No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Job Task No."), Expense."Job Task No.", ExpenseLedgerEntry.TableCaption()));
    end;

    local procedure VerifyJobLedgerEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line"; AccountNo: Code[20]; ExpectedCurrencyCode: Code[10]; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
#pragma warning disable AA0210
        JobLedgerEntry.SetRange("Expense Report No.", PostedExpenseReportLine."Document No.");
        JobLedgerEntry.SetRange("Expense Report Line No.", PostedExpenseReportLine."Line No.");
#pragma warning restore AA0210
        JobLedgerEntry.FindFirst();
        Assert.RecordCount(JobLedgerEntry, 1);

        Assert.AreEqual(
            PostedExpenseReportHeader."Posting Date",
            JobLedgerEntry."Posting Date",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Posting Date"), PostedExpenseReportHeader."Posting Date", JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportHeader."No.",
            JobLedgerEntry."Document No.",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Document No."), PostedExpenseReportHeader."No.", JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Job No.",
            JobLedgerEntry."Job No.",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Job No."), PostedExpenseReportLine."Job No.", JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Job Task No.",
            JobLedgerEntry."Job Task No.",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Job Task No."), PostedExpenseReportLine."Job Task No.", JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            JobLedgerEntry.Type::"G/L Account",
            JobLedgerEntry.Type,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Type"), JobLedgerEntry.Type::"G/L Account", JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            AccountNo,
            JobLedgerEntry."No.",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("No."), AccountNo, JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            1,
            JobLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Quantity"), 1, JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            ExpectedCurrencyCode,
            JobLedgerEntry."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Currency Code"), ExpectedCurrencyCode, JobLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedAmount,
            JobLedgerEntry."Unit Price",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Unit Price"), ExpectedAmount, JobLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedAmountLCY,
            JobLedgerEntry."Unit Price (LCY)",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Unit Price (LCY)"), ExpectedAmountLCY, JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            JobLedgerEntry."Entry No.",
            PostedExpenseReportLine."Job Ledger Entry No.",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Job Ledger Entry No."), JobLedgerEntry."Entry No.", PostedExpenseReportLine.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedAmount,
            JobLedgerEntry."Unit Cost",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Unit Cost"), ExpectedAmount, JobLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedAmountLCY,
            JobLedgerEntry."Unit Cost (LCY)",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Unit Cost (LCY)"), ExpectedAmountLCY, JobLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedAmount,
            JobLedgerEntry."Unit Cost",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Unit Cost"), ExpectedAmount, JobLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedAmountLCY,
            JobLedgerEntry."Unit Cost (LCY)",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Unit Cost (LCY)"), ExpectedAmountLCY, JobLedgerEntry.TableCaption()));
    end;

    local procedure VerifyDimensionFromDimensionSetID(DimSetID: Integer; ExpectedCount: Integer; ExpectedDimensionValue: Record "Dimension Value")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionMgt: Codeunit DimensionManagement;
    begin
        DimensionMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        Assert.RecordCount(TempDimSetEntry, ExpectedCount);

        TempDimSetEntry.SetRange("Dimension Code", ExpectedDimensionValue."Dimension Code");
        TempDimSetEntry.FindFirst();

        Assert.AreEqual(
            ExpectedDimensionValue.Code,
            TempDimSetEntry."Dimension Value Code",
            StrSubstNo(ValueMustBeEqualErr, TempDimSetEntry.FieldCaption("Dimension Value Code"), ExpectedDimensionValue.Code, TempDimSetEntry.TableCaption()));
    end;

    local procedure GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser: Record "Expense User"): Code[20]
    var
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        Employee.Get(ExpenseUser."Employee No.");
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        exit(EmployeePostingGroup.GetExpenseReportPayablesAccount());
    end;

    local procedure VerifyRecordCountOfGLEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; ExpectedRecordCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(GLEntry, ExpectedRecordCount);
    end;

    local procedure VerifyEmployeeLedgerEntry(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
#pragma warning disable AA0210
        EmployeeLedgerEntry.SetRange("Document Type", EmployeeLedgerEntry."Document Type"::Invoice);
        EmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
#pragma warning restore AA0210
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields("Amount (LCY)");

        Assert.AreNearlyEqual(
            ExpectedAmount,
            EmployeeLedgerEntry."Amount (LCY)",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, EmployeeLedgerEntry.FieldCaption("Amount (LCY)"), ExpectedAmount, EmployeeLedgerEntry.TableCaption()));
    end;

    local procedure VerifyDetailedEmployeeLedgerEntry(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        DetailedEmployeeLedgerEntry.SetRange("Document Type", DetailedEmployeeLedgerEntry."Document Type"::Invoice);
        DetailedEmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedEmployeeLedgerEntry.CalcSums("Amount (LCY)");

        Assert.AreNearlyEqual(
            ExpectedAmount,
            DetailedEmployeeLedgerEntry."Amount (LCY)",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, DetailedEmployeeLedgerEntry.FieldCaption("Amount (LCY)"), ExpectedAmount, DetailedEmployeeLedgerEntry.TableCaption()));
    end;

    local procedure CreateAndPostExpenseReportWithJob(var Expense: Record Expense; var ExpenseUser: Record "Expense User"; var ExpensePaymentMethod: Record "Expense Payment Method"; var JobTask: Record "Job Task"; var ExpenseReportHeader: Record "Expense Report Header"; ReimbursementType: Enum "Expense Reimbursement Type"; CurrencyCode: Code[10]; JobCurrencyCode: Code[10]; Amount: Decimal)
    var
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, ReimbursementType, true, CurrencyCode, JobCurrencyCode, 0, Amount);
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
    end;

    local procedure VerifyPostedExpenseReportWithJob(Expense: Record Expense; ExpenseUser: Record "Expense User"; JobCurrencyCode: Code[10]; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyRecordCountOfGLEntry(PostedExpenseReportHeader, 2);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), JobCurrencyCode, ExpectedAmount, ExpectedAmountLCY);
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExpenseBillingInformationModalPageErrorHandler(var ExpenseBillingInformation: TestPage "Expense Billing Information")
    begin
        ExpenseBillingInformation."Expense Ext. Doc. No.".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseBillingInformation."Merchant Name".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseBillingInformation.Ok().Invoke();
    end;

    [PageHandler]
    procedure PostedExpenseReportModalPageHandler(var PostedExpenseReport: TestPage "Posted Expense Report")
    begin
        PostedExpenseReport.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [SendNotificationHandler]
    procedure SentNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;
}