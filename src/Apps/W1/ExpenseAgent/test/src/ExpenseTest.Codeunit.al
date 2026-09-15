// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.TestLibraries.Foundation.NoSeries;
using System;
using System.Automation;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Environment;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 148305 "Expense Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNoSeries: Codeunit "Library - No. Series";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        IsInitialized: Boolean;
        AddExpenseTo: Option "New Expense Report","Existing Expense Report";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        CannotAssignManuallyErr: Label 'You may not enter numbers manually. If you want to enter numbers manually, please activate %1 in %2 %3.', Comment = '%1 = Manual Nos. setting, %2 = No. Series table caption, %3 = No. Series Code';
        CannotModifyWithItemizationErr: Label 'You cannot modify %1 field of expense %2 because it has associated itemizations.', Comment = '%1 = Field Name, %2 = Expense No.';
        CannotModifyWithParticipantsErr: Label 'You cannot modify %1 field of expense %2 because it has associated participants.', Comment = '%1 = Field Name, %2 = Expense No.';
        CannotDeleteWithExpenseReportErr: Label 'You cannot delete expense %1 because it is associated with expense report %2.', Comment = '%1 = Expense No., %2 = Expense Report No.';
        BatchCompletedMsg: Label 'All of your selections were processed.';
        CannotAddItemizationErr: Label 'Cannot add Itemizations to Expense No. %1 as there is no applicable Expense Rule that requires itemizations.', Comment = '%1 - Expense No.';
        ItemizationTotalMismatchErr: Label 'Itemization total %1 must be equal to expense amount %2.', Comment = '%1 = Itemization total amount, %2 = Expense amount';
        OnlyUseExpenseLocationWithPerDiemErr: Label 'The selected Expense Location %1 and Expense Category %2 can only be used with per diem expenses on Expense No. %3.', Comment = '%1 = Expense Location, %2 = Expense Category, %3 = Expense No.';
        FieldShouldBeVisibleErr: Label '%1 should be visible in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        FieldShouldNotBeVisibleErr: Label '%1 should not be visible in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        ParticipantActionShouldBeVisibleErr: Label 'Participant action should be visible in Page %1', Comment = '%1 = Page Caption';
        ItemizeActionShouldBeVisibleErr: Label 'Itemize action should be visible in Page %1', Comment = '%1 = Page Caption';
        PerDiemActionShouldBeVisibleErr: Label 'Per Diem action should be visible in Page %1', Comment = '%1 = Page Caption';
        ItemizeActionShouldNotBeVisibleErr: Label 'Itemize action should not be visible in Page %1', Comment = '%1 = Page Caption';
        ParticipantActionShouldNotBeVisibleErr: Label 'Participant action should not be visible in Page %1', Comment = '%1 = Page Caption';
        PerDiemActionShouldNotBeVisibleErr: Label 'Per Diem action should not be visible in Page %1', Comment = '%1 = Page Caption';
        FieldShouldNotBeEditableErr: Label '%1 should not be editable in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        FieldShouldBeEditableErr: Label '%1 should be editable in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        ParticipantEmployeeMustBeRequiredInExpenseErr: Label '%1 must be required in Expense No.=%2, Line No.=%3.', Comment = '%1 = Field Caption, %2 = Expense No., %3 = Line No.';
        PerDiemRequiredErr: Label 'Per Diem details are required for this expense based on your organization''s rule.';
        ConflictingExpenseLocationErr: Label 'Expense Location %1 conflicts with existing Expense Location %2 having the same Country/Region Code %3, County %4, and City %5.', Comment = '%1 - Location No., %2 - Existing Location No., %3 - Country/Region Code, %4 - County, %5 - City';
        CanOverwriteEmployeeInformationQst: Label 'Do you want to overwrite the employee Name and E-Mail on Expense User from Employee information of %1?', Comment = '%1 - Employee No.';
        ExistingExpenseTeamManagerErr: Label 'There is already a Team Manager (%1) for Expense Team %2.', Comment = '%1 - Expense User Number %2 -Expense Team Code';
        CannotInsertPerDiemInfoErr: Label 'New method failed because Insert is not allowed.';
        JPEGLbl: Label '.jpeg', Locked = true;
        PDFLbl: Label '.pdf', Locked = true;
        DocumentAttachmentDoesNotExistErr: Label 'Document Attachment does not exist on %1.', Comment = '%1 - Table Caption';
        ItemizationTotalReductionMismatchErr: Label 'Itemization total reduction %1 must be equal to expense reduction amount %2.', Comment = '%1 = Itemization total reduction amount, %2 = Expense reductionamount';
        ExpenseDocumentAttachmentMandatoryMsg: Label 'Document Attachment is mandatory on Expense No. %1', Comment = '%1 = Expense No.';
        ExpenseAttachmentMissingMsg: Label 'Attachments are missing in Expense No. %1.', Comment = '%1 = Expense No.';
        MaxAmountErr: Label 'Amount must not exceed %1 as defined by rule.', Comment = '%1 = Maximum allowed amount';
        PDFPreviewShouldBeVisibleErr: Label 'PDF Preview factbox should be visible on %1.', Comment = '%1 = Page Caption';
        PDFPreviewShouldNotBeVisibleErr: Label 'PDF Preview factbox should not be visible on %1.', Comment = '%1 = Page Caption';
        HasPDFAttachmentShouldBeTrueErr: Label 'HasPDFAttachment should return true.';
        HasPDFAttachmentShouldBeFalseErr: Label 'HasPDFAttachment should return false.';
        PDFTestContentLbl: Label 'PDF test content';
        OnlyMyExpenseExpectedErr: Label 'Expense %1 should be visible after Show My Expenses is invoked.', Comment = '%1 = Expense No. that should be the only row';
        ExpenseVendorNosShouldBeSetErr: Label 'Expense Vendor Nos. should be set when no. series defaults are created.';

    [Test]
    procedure NoCannotBeUpdatedInExpenseManuallyIfManualNosIsFalse()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        NoSeries: Record "No. Series";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "No." field cannot be updated in Expense If "Manual Nos." is set to false in "No. Series".
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Get "No. Series" and Update "Manual Nos." to false.
        NoSeries.Get(Expense."No. Series");
        NoSeries.Validate("Manual Nos.", false);
        NoSeries.Modify();

        // [WHEN] Update "No." in Expense.
        asserterror Expense.Validate("No.", LibraryUtility.GenerateRandomCode(Expense.FieldNo("No."), Database::Expense));

        // [THEN] Verify that system must throw an error When "No." field is updated in Expense.
        Assert.ExpectedError(StrSubstNo(CannotAssignManuallyErr, NoSeries.FieldCaption("Manual Nos."), NoSeries.TableCaption(), NoSeries.Code));
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    procedure CreateExpenseFromBlankCardWithRelatedNoSeries()
    var
        Expense: Record Expense;
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        RelatedNoSeriesLine: Record "No. Series Line";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpensePage: TestPage "Expense";
        ExpectedExpenseNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that the related No. Series is used When creating Expense from blank card.
        Initialize();

        // [GIVEN] Create No. Series and Related No. Series.
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(RelatedNoSeriesLine, RelatedNoSeries.Code, '', '');

        // [GIVEN] Get Expected Expense No. from Related No. Series.
        ExpectedExpenseNo := LibraryUtility.GetNextNoFromNoSeries(RelatedNoSeries.Code, WorkDate());

        // [GIVEN] Create No. Series.
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);

        // [GIVEN] Setup Number Series in Expense Management.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Expense Nos.", NoSeries.Code);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Store Related No. Series Code in Variable Storage.
        LibraryVariableStorage.Enqueue(RelatedNoSeries.Code);

        // [WHEN] Create Expense.
        ExpensePage.OpenNew();
        ExpensePage."No.".AssistEdit();
        ExpensePage.Close();

        // [THEN] Verify that the Expense is created with Related No. Series.
        Expense.Get(ExpectedExpenseNo);
        Assert.AreEqual(
           RelatedNoSeries.Code,
           Expense."No. Series",
           StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("No. Series"), RelatedNoSeries.Code, Expense.TableCaption()));
        Assert.AreEqual(
           ExpectedExpenseNo,
           Expense."No.",
           StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("No."), ExpectedExpenseNo, Expense.TableCaption()));
    end;

    [Test]
    procedure ExpenseNosIsRequiredWhenCreatingExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Expense Nos." is required When creating Expense.
        Initialize();

        // [GIVEN] Setup Number Series in Expense Management.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Expense Nos.", '');
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [WHEN] Create Expense.
        asserterror CreateExpense(Expense, true, CurrencyCode, LibraryRandom.RandInt(100));

        // [THEN] Verify that system must throw an error When "Expense Nos." is empty in Expense Agent Setup.
        Assert.ExpectedTestFieldError(ExpenseAgentSetup.FieldCaption("Expense Nos."), '');
    end;

    [Test]
    procedure ExpenseVendorNosIsSetByCreateNoSeriesDefaults()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO] Verify that Expense Vendor Nos. is set when creating no. series defaults.
        Initialize();

        // [GIVEN] Expense Vendor Nos. is blank.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Expense Vendor Nos.", '');
        ExpenseAgentSetup.Validate("No. Series Applied", false);
        ExpenseAgentSetup.Modify(true);

        // [WHEN] Create no. series defaults.
        ExpenseAgentSetup.CreateNoSeriesDefaults();

        // [THEN] Expense Vendor Nos. is populated and no. series is marked as applied.
        ExpenseAgentSetup.Get();
        Assert.IsTrue(ExpenseAgentSetup."Expense Vendor Nos." <> '', ExpenseVendorNosShouldBeSetErr);
        Assert.IsTrue(ExpenseAgentSetup."No. Series Applied", StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("No. Series Applied"), true, ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    procedure ExpenseVendorNosIsNotOverwrittenByCreateNoSeriesDefaults()
    var
        NoSeries: Record "No. Series";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExistingExpenseVendorNos: Code[20];
    begin
        // [SCENARIO] Verify that Expense Vendor Nos. is not overwritten when creating no. series defaults.
        Initialize();

        // [GIVEN] Expense Vendor Nos. has an existing value.
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        ExistingExpenseVendorNos := NoSeries.Code;

        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Expense Vendor Nos.", ExistingExpenseVendorNos);
        ExpenseAgentSetup.Validate("No. Series Applied", false);
        ExpenseAgentSetup.Modify(true);

        // [WHEN] Create no. series defaults.
        ExpenseAgentSetup.CreateNoSeriesDefaults();

        // [THEN] Existing Expense Vendor Nos. value is preserved.
        ExpenseAgentSetup.Get();
        Assert.AreEqual(
            ExistingExpenseVendorNos,
            ExpenseAgentSetup."Expense Vendor Nos.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Expense Vendor Nos."), ExistingExpenseVendorNos, ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    procedure NoBeUpdatedInExpenseManuallyIfManualNosIsTrue()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        NoSeries: Record "No. Series";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CurrencyCode: Code[10];
        ManualNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that the "No." field can be updated in Expense If "Manual Nos." is set to true in "No. Series".
        Initialize();

        // [GIVEN] Setup Number Series in Expense Management.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Expense Nos.", '');
        ExpenseAgentSetup.Modify();

        // [GIVEN] Setup Number Series in Expense Management.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Manual No.
        ManualNo := LibraryUtility.GenerateRandomCode(Expense.FieldNo("No."), Database::Expense);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Get "No. Series" and Update "Manual Nos." to true.
        NoSeries.Get(Expense."No. Series");
        NoSeries.Validate("Manual Nos.", true);
        NoSeries.Modify();

        // [WHEN] Update "No." in Expense.
        Expense.Validate("No.", ManualNo);

        // [THEN] Verify that the "No." field is updated in Expense.
        Assert.AreEqual(
            ManualNo,
            Expense."No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("No."), Expense."No.", Expense.TableCaption()));
        Assert.AreEqual(
            '',
            Expense."No. Series",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("No. Series"), '', Expense.TableCaption()));
    end;

    [Test]
    procedure NoSeriesCannotBeChangedWhenSameNoIsUpdatedAgainInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        NoSeries: Record "No. Series";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "No. Series" cannot be changed When same "No." is updated again in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Get "No. Series".
        NoSeries.Get(Expense."No. Series");

        // [WHEN] Update "No." in Expense.
        Expense.Validate("No.", Expense."No.");

        // [THEN] Verify that the "No. Series" is not changed in Expense.
        Assert.AreEqual(
            NoSeries.Code,
            Expense."No. Series",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("No. Series"), NoSeries.Code, Expense.TableCaption()));
    end;

    [Test]
    procedure FieldsCannotBeChangedWhenExpenseIsReleased()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the some fields cannot be changed When Expense is released.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, LibraryRandom.RandInt(100));
        Expense.Validate("Merchant Name", LibraryRandom.RandText(20));
        Expense.Validate("Expense Ext. Doc. No.", LibraryRandom.RandText(20));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Save Expense.
        Commit();

        // [WHEN] Update "Expense User No." in Expense.
        asserterror Expense.Validate("Expense User No.", '');

        // [THEN] Verify that the "Expense User No." cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Expense Category" in Expense.
        asserterror Expense.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Expense Subcategory" in Expense.
        asserterror Expense.Validate("Expense Subcategory", '');

        // [THEN] Verify that the "Expense Subcategory" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Unit of Measure Code" in Expense.
        asserterror Expense.Validate("Unit of Measure Code", '');

        // [THEN] Verify that the "Unit of Measure Code" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Description" in Expense.
        asserterror Expense.Validate(Description, '');

        // [THEN] Verify that the "Description" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Justification" in Expense.
        asserterror Expense.Validate(Justification, '');

        // [THEN] Verify that the "Justification" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Expense Date" in Expense.
        asserterror Expense.Validate("Expense Date", Today);

        // [THEN] Verify that the "Expense Date" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Expense Time" in Expense.
        asserterror Expense.Validate("Expense Time", Time);

        // [THEN] Verify that the "Expense Time" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Currency Code" in Expense.
        asserterror Expense.Validate("Currency Code", '');

        // [THEN] Verify that the "Currency Code" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Currency Code" in Expense.
        asserterror Expense.Validate("Currency Code", '');

        // [THEN] Verify that the "Currency Code" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update Amount in Expense.
        asserterror Expense.Validate(Amount, 0);

        // [THEN] Verify that the "Amount" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Merchant Name" in Expense.
        asserterror Expense.Validate("Merchant Name", '');

        // [THEN] Verify that the "Merchant Name" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Receipt Entry" in Expense.
        asserterror Expense.Validate("Receipt Entry", 0);

        // [THEN] Verify that the "Receipt Entry" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Shortcut Dimension 1 Code" in Expense.
        asserterror Expense.Validate("Shortcut Dimension 1 Code");

        // [THEN] Verify that the "Shortcut Dimension 1 Code" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Starting Date and Time" in Expense.
        asserterror Expense.Validate("Starting Date and Time", CreateDateTime(WorkDate(), Time));

        // [THEN] Verify that the "Starting Date and Time" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Ending Date and Time" in Expense.
        asserterror Expense.Validate("Ending Date and Time", CreateDateTime(WorkDate(), Time));

        // [THEN] Verify that the "Ending Date and Time" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Expense Location" in Expense.
        asserterror Expense.Validate("Expense Location", '');

        // [THEN] Verify that the "Expense Location" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Shortcut Dimension 2 Code" in Expense.
        asserterror Expense.Validate("Shortcut Dimension 2 Code", '');

        // [THEN] Verify that the "Shortcut Dimension 2 Code" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Payment Method Code" in Expense.
        asserterror Expense.Validate("Payment Method Code", '');

        // [THEN] Verify that the "Payment Method Code" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Refundable" in Expense.
        asserterror Expense.Validate(Refundable, true);

        // [THEN] Verify that the "Refundable" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Billable" in Expense.
        asserterror Expense.Validate(Billable, true);

        // [THEN] Verify that the "Billable" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Billable to Customer" in Expense.
        asserterror Expense.Validate("Billable to Customer", '');

        // [THEN] Verify that the "Billable to Customer" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Non-Refundable Amount" in Expense.
        asserterror Expense.Validate("Non-Refundable Amount", LibraryRandom.RandDec(100, 2));

        // [THEN] Verify that the "Non-Refundable Amount" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Mileage" in Expense.
        asserterror Expense.Validate(Mileage, LibraryRandom.RandDec(100, 2));

        // [THEN] Verify that the "Mileage" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Starting Point" in Expense.
        asserterror Expense.Validate("Starting Point", '');

        // [THEN] Verify that the "Starting Point" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Ending Point" in Expense.
        asserterror Expense.Validate("Ending Point", '');

        // [THEN] Verify that the "Ending Point" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Reimbursable Amount" in Expense.
        asserterror Expense.Validate("Reimbursable Amount", LibraryRandom.RandDec(100, 2));

        // [THEN] Verify that the "Reimbursable Amount" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Credit Card Feed No." in Expense.
        asserterror Expense.Validate("Credit Card Feed No.", LibraryRandom.RandInt(100));

        // [THEN] Verify that the "Credit Card Feed No." cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "VAT Bus. Posting Group" in Expense.
        asserterror Expense.Validate("VAT Bus. Posting Group", '');

        // [THEN] Verify that the "VAT Bus. Posting Group" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "VAT Prod. Posting Group" in Expense.
        asserterror Expense.Validate("VAT Prod. Posting Group", '');

        // [THEN] Verify that the "VAT Prod. Posting Group" cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Job No." in Expense.
        asserterror Expense.Validate("Job No.", '');

        // [THEN] Verify that the "Job No." cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Job Task No." in Expense.
        asserterror Expense.Validate("Job Task No.", '');

        // [THEN] Verify that the "Job Task No." cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));

        // [WHEN] Update "Expense Ext. Doc. No." in Expense.
        asserterror Expense.Validate("Expense Ext. Doc. No.", '');

        // [THEN] Verify that the "Expense Ext. Doc. No." cannot be changed in Expense.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));
    end;

    [Test]
    procedure FieldsCanBeChangedWhenExpenseIsReleased()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CurrencyCode: Code[10];
        ExtractionConfidence: Integer;
    begin
        // [SCENARIO 580546] Verify that the some fields can be changed When Expense is released.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate "Expense Ext. Doc. No." and "Extraction Confidence".
        ExtractionConfidence := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [WHEN] Update "Expense Ext. Doc. No." in Expense.
        Expense.Validate("Extraction Confidence", ExtractionConfidence);

        // [THEN] Verify that the "Extraction Confidence" can be changed in Expense.
        Assert.AreEqual(
            ExtractionConfidence,
            Expense."Extraction Confidence",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Extraction Confidence"), ExtractionConfidence, Expense.TableCaption()));
    end;

    [Test]
    procedure FieldsCannotBeChangedWhenExpenseItemizationIsCreated()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the some fields cannot be changed When Expense Itemization is created.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Save Expense.
        Commit();

        // [WHEN] Update "No." in Expense.
        asserterror Expense.Validate("No.", '');

        // [THEN] Verify that the "No." cannot be changed in Expense.
        Assert.ExpectedError(StrSubstNo(CannotModifyWithItemizationErr, Expense.FieldCaption("No."), Expense."No."));
    end;

    [Test]
    procedure FieldsCannotBeChangedWhenExpenseParticipantIsCreated()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the some fields cannot be changed When Expense Participant is created.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Save Expense.
        Commit();

        // [WHEN] Update "No." in Expense.
        asserterror Expense.Validate("No.", '');

        // [THEN] Verify that the "No." cannot be changed in Expense.
        Assert.ExpectedError(StrSubstNo(CannotModifyWithParticipantsErr, Expense.FieldCaption("No."), Expense."No."));
    end;

    [Test]
    procedure FieldsCanBeChangedWhenExpensePerDiemIsCreated()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616941] Verify that the some fields can be changed When Expense Per Diem is created.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [WHEN] Update "No.","Expense Category" in Expense.
        Expense.Validate("No.", '');
        Expense.Validate("Expense Category", '');

        // [THEN] Verify that the "No.","Expense Category" can be changed in Expense.
        Assert.AreEqual(
            '',
            Expense."Expense Location",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Location"), '', Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ItemizationDeletedWhenExpenseCategoryChangedAndConfirmed()
    var
        Expense: Record Expense;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseItemization: Record "Expense Itemization";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 639727] Verify that the associated Itemization is deleted and "Expense Category" is changed When the user confirms the deletion.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, '', '', CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Save Expense.
        Commit();

        // [WHEN] Update "Expense Category" in Expense and confirm the deletion of associated records.
        Expense.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is changed in Expense.
        Assert.AreEqual(
            '',
            Expense."Expense Category",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Category"), '', Expense.TableCaption()));

        // [THEN] Verify that the associated Itemization is deleted.
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseItemization, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure ItemizationKeptWhenExpenseCategoryChangedAndNotConfirmed()
    var
        Expense: Record Expense;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseItemization: Record "Expense Itemization";
        OriginalCategory: Code[20];
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 639727] Verify that the associated Itemization is kept and "Expense Category" is not changed When the user declines the deletion.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, '', '', CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Store the original "Expense Category".
        OriginalCategory := Expense."Expense Category";

        // [GIVEN] Save Expense.
        Commit();

        // [WHEN] Update "Expense Category" in Expense and decline the deletion of associated records.
        asserterror Expense.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is not changed in Expense.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            OriginalCategory,
            Expense."Expense Category",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Category"), OriginalCategory, Expense.TableCaption()));

        // [THEN] Verify that the associated Itemization is kept.
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseItemization, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ParticipantDeletedWhenExpenseCategoryChangedAndConfirmed()
    var
        Expense: Record Expense;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 639727] Verify that the associated Participant is deleted and "Expense Category" is changed When the user confirms the deletion.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, '', '', CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense User", "Employee" and Update Expense Account in "Employee Posting Group".
        ExpenseUser.Get(Expense."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Save Expense.
        Commit();

        // [WHEN] Update "Expense Category" in Expense and confirm the deletion of associated records.
        Expense.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is changed in Expense.
        Assert.AreEqual(
            '',
            Expense."Expense Category",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Category"), '', Expense.TableCaption()));

        // [THEN] Verify that the associated Participant is deleted.
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseParticipant, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure ParticipantKeptWhenExpenseCategoryChangedAndNotConfirmed()
    var
        Expense: Record Expense;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        OriginalCategory: Code[20];
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 639727] Verify that the associated Participant is kept and "Expense Category" is not changed When the user declines the deletion.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, '', '', CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense User", "Employee" and Update Expense Account in "Employee Posting Group".
        ExpenseUser.Get(Expense."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Store the original "Expense Category".
        OriginalCategory := Expense."Expense Category";

        // [GIVEN] Save Expense.
        Commit();

        // [WHEN] Update "Expense Category" in Expense and decline the deletion of associated records.
        asserterror Expense.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is not changed in Expense.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            OriginalCategory,
            Expense."Expense Category",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Category"), OriginalCategory, Expense.TableCaption()));

        // [THEN] Verify that the associated Participant is kept.
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseParticipant, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PerDiemDeletedWhenExpenseCategoryChangedAndConfirmed()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePerDiem: Record "Expense Per Diem";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 639727] Verify that the associated Per Diem is deleted and "Expense Category" is changed When the user confirms the deletion.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense User", "Employee" and Update Expense Account in "Employee Posting Group".
        ExpenseUser.Get(Expense."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Apply Rule on Expense to create the associated Per Diem.
        Expense.ApplyRule();

        // [GIVEN] Save Expense.
        Commit();

        // [WHEN] Update "Expense Category" in Expense and confirm the deletion of associated records.
        Expense.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is changed in Expense.
        Assert.AreEqual(
            '',
            Expense."Expense Category",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Category"), '', Expense.TableCaption()));

        // [THEN] Verify that the associated Per Diem is deleted.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpensePerDiem, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure PerDiemKeptWhenExpenseCategoryChangedAndNotConfirmed()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePerDiem: Record "Expense Per Diem";
        OriginalCategory: Code[20];
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 639727] Verify that the associated Per Diem is kept and "Expense Category" is not changed When the user declines the deletion.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense User", "Employee" and Update Expense Account in "Employee Posting Group".
        ExpenseUser.Get(Expense."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Apply Rule on Expense to create the associated Per Diem.
        Expense.ApplyRule();

        // [GIVEN] Store the original "Expense Category".
        OriginalCategory := Expense."Expense Category";

        // [GIVEN] Save Expense.
        Commit();

        // [WHEN] Update "Expense Category" in Expense and decline the deletion of associated records.
        asserterror Expense.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is not changed in Expense.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            OriginalCategory,
            Expense."Expense Category",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Category"), OriginalCategory, Expense.TableCaption()));

        // [THEN] Verify that the associated Per Diem is kept.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpensePerDiem, 1);
    end;

    [Test]
    procedure AssociatedRecordsAutoDeletedWhenExpenseCategoryChangedWithHiddenValidation()
    var
        Expense: Record Expense;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseItemization: Record "Expense Itemization";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 639727] Verify that the associated records are deleted automatically without confirmation When the validation dialog is hidden (Expense Agent path).
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, '', '', CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Save Expense.
        Commit();

        // [GIVEN] Hide the validation dialog to simulate the Expense Agent path.
        Expense.SetHideValidationDialog(true);

        // [WHEN] Update "Expense Category" in Expense.
        Expense.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is changed in Expense.
        Assert.AreEqual(
            '',
            Expense."Expense Category",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Category"), '', Expense.TableCaption()));

        // [THEN] Verify that the associated Itemization is deleted automatically.
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseItemization, 0);
    end;

    [Test]
    procedure ExpenseDateMustBeEqualToWorkDateWhenExpenseIsInserted()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Expense Date" must be equal to Work Date When Expense is inserted.
        Initialize();

        // [GIVEN] Setup Number Series in Expense Management.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [WHEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, LibraryRandom.RandInt(100));

        // [THEN] Verify that the "Expense Date" is equal to Work Date in Expense.
        Assert.AreEqual(
            WorkDate(),
            Expense."Expense Date",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Date"), '', Expense.TableCaption()));
    end;

    [Test]
    procedure ExpenseCanBeDeletedWhenItemizationExists()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621783] Verify that the Expense can be deleted When Itemization exists.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [WHEN] Delete Expense.
        Expense.Delete(true);

        // [THEN] Verify that the Expense is deleted.
        Expense.SetRange("No.", Expense."No.");
        Assert.RecordCount(Expense, 0);

        // [THEN] Verify that the Expense Itemization is deleted.
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseItemization, 0);
    end;

    [Test]
    procedure ExpenseCanBeDeletedWhenParticipantExists()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621783] Verify that the Expense can be deleted When Participant exists.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [WHEN] Delete Expense.
        Expense.Delete(true);

        // [THEN] Verify that the Expense is deleted.
        Expense.SetRange("No.", Expense."No.");
        Assert.RecordCount(Expense, 0);

        // [THEN] Verify that the Expense Participant is deleted.
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseParticipant, 0);
    end;

    [Test]
    procedure ExpenseCanBeDeletedWhenExpensePerDiemExists()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpensePerDiem: Record "Expense Per Diem";
        EmployeePostingGroup: Record "Employee Posting Group";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621783] Verify that the Expense can be deleted When Expense Per Diem exists.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [WHEN] Delete Expense.
        Expense.Delete(true);

        // [THEN] Verify that the Expense is deleted.
        Expense.SetRange("No.", Expense."No.");
        Assert.RecordCount(Expense, 0);

        // [THEN] Verify that the Expense Per Diem is deleted.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpensePerDiem, 0);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseCannotBeDeletedWhenExpenseIsLinkedWithExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the Expense cannot be deleted When Expense is linked with Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense Line.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [WHEN] Delete Expense.
        Expense.Get(Expense."No.");
        asserterror Expense.Delete(true);

        // [THEN] Verify that the Expense cannot be deleted When Expense is linked with Expense Report.
        Assert.ExpectedError(StrSubstNo(CannotDeleteWithExpenseReportErr, Expense."No.", ExpenseReportHeader."No."));
    end;

    [Test]
    procedure DimensionSetIDMustBeUpdatedWhenShortcutDimensionsAreUpdatedInExpense()
    var
        DimValue: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        Expense: Record Expense;
        Currency: Record Currency;
        CurrencyCode: Code[10];
        ExpectedDimSetID: Integer;
    begin
        // [SCENARIO 580546] Verify that the "Dimension Set ID" must be updated When Shortcut Dimensions are updated in Expense.
        Initialize();

        // [GIVEN] Create Global Dimension Value 1 and 2.
        LibraryDimension.GetGlobalDimCodeValue(1, DimValue);
        LibraryDimension.GetGlobalDimCodeValue(2, DimValue2);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [WHEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Get Expected Dimension Set ID after adding Dimension Value 1 and 2.
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimValue);
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimValue2);

        // [WHEN] Update Shortcut Dimension 1 and 2 in Expense.
        Expense.Validate("Shortcut Dimension 1 Code", DimValue.Code);
        Expense.Validate("Shortcut Dimension 2 Code", DimValue2.Code);

        // [THEN] Verify that the "Dimension Set ID" is updated in Expense.
        Assert.AreEqual(
            ExpectedDimSetID,
            Expense."Dimension Set ID",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Dimension Set ID"), ExpectedDimSetID, Expense.TableCaption()));
        Assert.AreEqual(
            DimValue.Code,
            Expense."Shortcut Dimension 1 Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Shortcut Dimension 1 Code"), DimValue.Code, Expense.TableCaption()));
        Assert.AreEqual(
            DimValue2.Code,
            Expense."Shortcut Dimension 2 Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Shortcut Dimension 2 Code"), DimValue2.Code, Expense.TableCaption()));
    end;

    [Test]
    procedure ShortcutDimensionsMustBeUpdatedWhenDimensionSetIDIsUpdatedInExpense()
    var
        DimValue: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        Expense: Record Expense;
        Currency: Record Currency;
        CurrencyCode: Code[10];
        ExpectedDimSetID: Integer;
    begin
        // [SCENARIO 580546] Verify that the Shortcut Dimensions must be updated When Dimension Set ID is updated in Expense.
        Initialize();

        // [GIVEN] Create Global Dimension Value 1 and 2.
        LibraryDimension.GetGlobalDimCodeValue(1, DimValue);
        LibraryDimension.GetGlobalDimCodeValue(2, DimValue2);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [WHEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Get Expected Dimension Set ID after adding Dimension Value 1 and 2.
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimValue);
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimValue2);

        // [WHEN] Update Dimension Set ID in Expense.
        Expense.Validate("Dimension Set ID", ExpectedDimSetID);

        // [THEN] Verify that the "Dimension Set ID" is updated in Expense.
        Assert.AreEqual(
            ExpectedDimSetID,
            Expense."Dimension Set ID",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Dimension Set ID"), ExpectedDimSetID, Expense.TableCaption()));
        Assert.AreEqual(
            DimValue.Code,
            Expense."Shortcut Dimension 1 Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Shortcut Dimension 1 Code"), DimValue.Code, Expense.TableCaption()));
        Assert.AreEqual(
            DimValue2.Code,
            Expense."Shortcut Dimension 2 Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Shortcut Dimension 2 Code"), DimValue2.Code, Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ExactMessageHandler')]
    procedure MultipleExpensesMustBeReleased()
    var
        ExpenseFilter: Record Expense;
        Expense: array[2] of Record Expense;
        Currency: Record Currency;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the Multiple Expenses must be released.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense.
        CreateExpense(Expense[1], true, CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Create another Expense.
        CreateExpense(Expense[2], true, CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Prepare expected Confirm and Message texts.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(BatchCompletedMsg);

        // [WHEN] Release Expenses.
        ExpenseFilter.SetFilter("No.", '%1|%2', Expense[1]."No.", Expense[2]."No.");
        ExpenseFilter.PerformManualRelease(ExpenseFilter);

        // [THEN] Verify that the Expenses are released.
        Expense[1].Get(Expense[1]."No.");
        Assert.AreEqual(
            Expense[1].Status::Released,
            Expense[1].Status,
            StrSubstNo(ValueMustBeEqualErr, Expense[1].FieldCaption(Status), Expense[1].Status::Released, Expense[1].TableCaption()));

        Expense[2].Get(Expense[2]."No.");
        Assert.AreEqual(
            Expense[2].Status::Released,
            Expense[2].Status,
            StrSubstNo(ValueMustBeEqualErr, Expense[2].FieldCaption(Status), Expense[2].Status::Released, Expense[2].TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ExactMessageHandler')]
    procedure MultipleExpensesMustBeReopen()
    var
        ExpenseFilter: Record Expense;
        Expense: array[2] of Record Expense;
        Currency: Record Currency;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the Multiple Expenses must be released.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense.
        CreateExpense(Expense[1], true, CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense[1]);

        // [GIVEN] Create another Expense.
        CreateExpense(Expense[2], true, CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense[2]);

        // [GIVEN] Prepare expected Confirm and Message texts.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(BatchCompletedMsg);

        // [WHEN] Release Expenses.
        ExpenseFilter.SetFilter("No.", '%1|%2', Expense[1]."No.", Expense[2]."No.");
        ExpenseFilter.PerformManualReopen(ExpenseFilter);

        // [THEN] Verify that the Expenses are released.
        Expense[1].Get(Expense[1]."No.");
        Assert.AreEqual(
            Expense[1].Status::Open,
            Expense[1].Status,
            StrSubstNo(ValueMustBeEqualErr, Expense[1].FieldCaption(Status), Expense[1].Status::Open, Expense[1].TableCaption()));

        Expense[2].Get(Expense[2]."No.");
        Assert.AreEqual(
            Expense[2].Status::Open,
            Expense[2].Status,
            StrSubstNo(ValueMustBeEqualErr, Expense[2].FieldCaption(Status), Expense[2].Status::Open, Expense[2].TableCaption()));
    end;

    [Test]
    procedure ApplyRuleCannotBeExecutedWhenExpenseIsReleased()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the Apply Rule cannot be executed When Expense is Released.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Release Expense.
        Expense.Status := Expense.Status::Released;
        Expense.Modify();

        // [GIVEN] Apply Rule on Expense.
        Expense.Get(Expense."No.");
        asserterror Expense.ApplyRule();

        // [THEN] Verify that the Apply Rule cannot be executed When Expense is Released.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));
    end;

    [Test]
    procedure RuleValidationIsExecutedWhenExpensePerDiemIsCleared()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePerDiem: Record "Expense Per Diem";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the Rule Validation is executed When Expense Per Diem is cleared.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Remove Currency Code from Expense.
        Expense.Validate("Currency Code", '');
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Clear Expense Per Diem entries.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        ExpensePerDiem.DeleteAll();

        // [GIVEN] Save Expense.
        Commit();

        // [WHEN] Validate Expense Against Rule.
        ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);

        // [THEN] Verify that the Rule Validation is executed When Expense Per Diem is cleared.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(PerDiemRequiredErr);
    end;

    [Test]
    procedure ExpenseLocationCanOnlyBeCreatedWithUniqueValue()
    var
        PostCode: Record "Post Code";
        ExpenseLocation: array[2] of Record "Expense Location";
    begin
        // [SCENARIO 613255] Verify that Location can only be created with unique value.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation[1], PostCode."Country/Region Code", PostCode.City);

        // [WHEN] Create another Expense Location with same Country/Region Code and City.
        asserterror LibraryExpense.CreateExpenseLocation(ExpenseLocation[2], PostCode."Country/Region Code", PostCode.City);

        // [THEN] Verify that Location can only be created with unique value.
        Assert.ExpectedError(
            StrSubstNo(
                ConflictingExpenseLocationErr,
                ExpenseLocation[2]."No.",
                ExpenseLocation[1]."No.",
                ExpenseLocation[1]."Country/Region Code",
                ExpenseLocation[1].County,
                ExpenseLocation[1].City));
    end;

    [Test]
    procedure CountyMustBeBlankWhenCountryIsUpdatedInExpenseLocation()
    var
        PostCode: Record "Post Code";
        ExpenseLocation: Record "Expense Location";
    begin
        // [SCENARIO 613255] Verify that County must be blank When "Country/Region Code" is updated.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [WHEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [THEN] Verify County must be blank When "Country/Region Code" is updated. 
        Assert.AreEqual(
            '',
            ExpenseLocation.County,
            StrSubstNo(ValueMustBeEqualErr, ExpenseLocation.FieldCaption(County), '', ExpenseLocation.TableCaption()));
    end;

    [Test]
    procedure ExpenseLocationCanOnlyBeModifiedWithUniqueValue()
    var
        PostCode: array[2] of Record "Post Code";
        ExpenseLocation: array[2] of Record "Expense Location";
    begin
        // [SCENARIO 613255] Verify that Location can only be modified with unique value.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode[1]);

        // [GIVEN] Find another "Post Code".
        LibraryERM.CreatePostCode(PostCode[2]);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation[1], PostCode[1]."Country/Region Code", PostCode[1].City);

        // [GIVEN] Create another Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation[2], PostCode[2]."Country/Region Code", PostCode[2].City);

        // [WHEN] Modify second Expense Location with same Country/Region Code and City as first Expense Location.
        ExpenseLocation[2].Validate("Country/Region Code", ExpenseLocation[1]."Country/Region Code");
        ExpenseLocation[2].Validate(City, ExpenseLocation[1].City);
        ExpenseLocation[2].Validate(County, ExpenseLocation[1].County);
        asserterror ExpenseLocation[2].Modify(true);

        // [THEN] Verify that Location can only be modified with unique value.
        Assert.ExpectedError(
            StrSubstNo(
                ConflictingExpenseLocationErr,
                ExpenseLocation[2]."No.",
                ExpenseLocation[1]."No.",
                ExpenseLocation[1]."Country/Region Code",
                ExpenseLocation[1].County,
                ExpenseLocation[1].City));
    end;

    [Test]
    procedure RefundableMustBeReflectedInExpenseFromExpenseCategory()
    var
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        Expense: Record Expense;
    begin
        // [SCENARIO 613262] Verify that Refundable must be reflected in Expense from Expense Category.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Create Expense with Expense Category.
        Expense.Init();
        Expense.Validate(Description, LibraryUtility.GenerateRandomCode(Expense.FieldNo(Description), Database::"Expense"));
        Expense.Validate("Expense User No.", ExpenseUser."No.");
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Insert(true);

        // [THEN] Verify that Refundable is reflected in Expense from Expense Category.
        Assert.AreEqual(
            true,
            Expense.Refundable,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Refundable), true, Expense.TableCaption()));
    end;

    [Test]
    procedure ExpenseItemizationCannotBeCreatedWhenExpenseRuleIsNotItemize()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseSubCategory: Record "Expense Subcategory";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613263] Verify that the Expense Itemization cannot be created When Expense Rule is not "Itemize".
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Save Expense.
        Commit();

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [WHEN] Create Expense Itemization.
        asserterror LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [THEN] Verify that the Expense Itemization cannot be created When Expense Rule is not "Itemize".
        Assert.ExpectedError(StrSubstNo(CannotAddItemizationErr, Expense."No."));
    end;

    [Test]
    [HandlerFunctions('VerifyAmountInExpenseItemizationsModalPageHandler')]
    procedure AmountMustBeAutoUpdatedInExpenseItemizationWhenDailyRateAndQuantityAreUpdated()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613263] Verify that the Amount must be auto-updated in Expense Itemization When Daily Rate and Quantity are updated.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [WHEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [THEN] Verify that the Amount is auto-updated in Expense Itemization When Daily Rate and Quantity are updated through Page Handler.
        LibraryVariableStorage.Enqueue(Amount);
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.Itemizations.Invoke();
    end;

    [Test]
    procedure CompanyEmailMustFlowInExpenseUserFromEmployee()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 614217] Verify that "Company E-Mail" must flow in Expense User from Employee.
        Initialize();

        // [GIVEN] Create Employee.
        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate("Company E-Mail", LibraryRandom.RandText(10) + '@example.com');
        Employee.Modify();

        // [WHEN] Create Expense User for Employee.
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Validate("Employee No.", Employee."No.");
        ExpenseUser.Insert(true);

        // [THEN] Verify that "Company E-Mail" is flowed in Expense User from Employee.
        Assert.AreEqual(
            Employee."Company E-Mail",
            ExpenseUser."E-mail",
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("E-mail"), Employee."Company E-Mail", ExpenseUser.TableCaption()));
    end;

    [Test]
    procedure ItemizationQuantityMustBeOneInExpenseByDefault()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614218] Verify that the Itemization Quantity must be 1 in Expense by default.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [WHEN] Create Expense Itemization.
        ExpenseItemization.Init();
        ExpenseItemization.Validate("Expense No.", Expense."No.");
        ExpenseItemization.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseItemization.FieldNo(Description), Database::"Expense Itemization"));
        ExpenseItemization.Insert();

        // [THEN] Verify that the Itemization Quantity is 1 in Expense by default.
        Assert.AreEqual(
            1,
            ExpenseItemization.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ExpenseItemization.FieldCaption(Quantity), 1, ExpenseItemization.TableCaption()));
    end;

    // This test is currently disabled via DisabledTests/Expense_Agent_Tests/Expense_Agent_Tests.DisabledTest.json because setting the Expense Itemization "Start Date" is validated against the license-allowed month window ('??11*|??12*|??01*|??02*'), and the CI WorkDate can fall outside that range.
    [Test]
    [HandlerFunctions('ExactMessageHandler,SetDateInExpenseItemizationsModalPageHandler')]
    procedure DescriptionMustBeFlowFromExpenseToExpenseItemization()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseItemization: Record "Expense Itemization";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613263] Verify that the Description must be flow from Expense to Expense Itemization.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Enqueue Expense SubCategory and Work Date for ExpenseItemizationsModalPageHandler.
        LibraryVariableStorage.Enqueue(Expense."Expense Subcategory");
        LibraryVariableStorage.Enqueue(WorkDate());

        // [GIVEN] Enqueue expected Message text.
        LibraryVariableStorage.Enqueue(StrSubstNo(ItemizationTotalMismatchErr, 0, Expense.Amount));

        // [WHEN] Open Expense Page and Navigate to Expense Itemizations.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.Itemizations.Invoke();

        // [THEN] Verify that the Description is flowed from Expense to Expense Itemization.
        ExpenseSubCategory.Get(Expense."Expense Category", Expense."Expense Subcategory");
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        ExpenseItemization.FindFirst();
        Assert.AreEqual(
            ExpenseSubCategory."Posting Description",
            ExpenseItemization.Description,
            StrSubstNo(ValueMustBeEqualErr, ExpenseItemization.FieldCaption(Description), ExpenseSubCategory."Posting Description", ExpenseItemization.TableCaption()));
    end;

    [Test]
    procedure ExpenseLocationCannotBeUpdatedWhenRuleIsItemize()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseLocation: Record "Expense Location";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613292] Verify that the Expense Location cannot be updated when Rule is Itemize.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [WHEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify Rule is Itemize.
        VerifyRuleIdInExpense(Expense, ExpenseRuleHeader);

        // [WHEN] Update Expense Location in Expense.
        asserterror Expense.Validate("Expense Location", ExpenseLocation."No.");

        // [THEN] Verify that the Expense Location cannot be updated when Rule is Itemize.
        Assert.ExpectedError(StrSubstNo(OnlyUseExpenseLocationWithPerDiemErr, ExpenseLocation."No.", Expense."Expense Category", Expense."No."));
    end;

    [Test]
    procedure ExpenseLocationCannotBeUpdatedWhenRuleIsMileage()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseLocation: Record "Expense Location";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613292] Verify that the Expense Location cannot be updated when Rule is Mileage.
        Initialize();

        // [GIVEN] Update Default Unit of Measure in Agent Setup.
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [WHEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify Rule is Mileage.
        VerifyRuleIdInExpense(Expense, ExpenseRuleHeader);

        // [WHEN] Update Expense Location in Expense.
        asserterror Expense.Validate("Expense Location", ExpenseLocation."No.");

        // [THEN] Verify that the Expense Location cannot be updated when Rule is Mileage.
        Assert.ExpectedError(StrSubstNo(OnlyUseExpenseLocationWithPerDiemErr, ExpenseLocation."No.", Expense."Expense Category", Expense."No."));
    end;

    [Test]
    procedure ExpenseLocationCannotBeUpdatedWhenRuleIsParticipants()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseLocation: Record "Expense Location";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613292] Verify that the Expense Location cannot be updated when Rule is Participants.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [WHEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify Rule is Participants.
        VerifyRuleIdInExpense(Expense, ExpenseRuleHeader);

        // [WHEN] Update Expense Location in Expense.
        asserterror Expense.Validate("Expense Location", ExpenseLocation."No.");

        // [THEN] Verify that the Expense Location cannot be updated when Rule is Participants.
        Assert.ExpectedError(StrSubstNo(OnlyUseExpenseLocationWithPerDiemErr, ExpenseLocation."No.", Expense."Expense Category", Expense."No."));
    end;

    [Test]
    procedure ExpenseFieldsMustNotBeVisibleWhenRuleIsItemized()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613292] Verify that the expense fields must not be visible when Rule is Itemized.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify Rule is Itemize.
        VerifyRuleIdInExpense(Expense, ExpenseRuleHeader);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that the expense fields are not visible when Rule is Itemized.
        Assert.AreEqual(
            false,
            ExpensePage."Starting Date and Time".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage."Starting Date and Time".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Ending Date and Time".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage."Ending Date and Time".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Starting Point".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage."Starting Point".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Ending Point".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage."Ending Point".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage.Mileage.Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage.Mileage.Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Unit of Measure Code".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage."Unit of Measure Code".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage.Participants.Visible(),
            StrSubstNo(ParticipantActionShouldNotBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           false,
           ExpensePage.PerDiem.Visible(),
           StrSubstNo(PerDiemActionShouldNotBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           true,
           ExpensePage.Itemizations.Visible(),
           StrSubstNo(ItemizeActionShouldBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           false,
           ExpensePage."Expense Location".Editable(),
           StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Expense Location".Caption(), ExpensePage.Caption()));
    end;

    [Test]
    procedure ExpenseFieldsMustNotBeVisibleWhenRuleIsParticipants()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613292] Verify that the expense fields must not be visible when Rule is Participants.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify Rule is Participants.
        VerifyRuleIdInExpense(Expense, ExpenseRuleHeader);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that the expense fields are not visible when Rule is Participants.
        Assert.AreEqual(
            false,
            ExpensePage."Starting Date and Time".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage."Starting Date and Time".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Ending Date and Time".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage."Ending Date and Time".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Starting Point".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage."Starting Point".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Ending Point".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage."Ending Point".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage.Mileage.Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage.Mileage.Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Unit of Measure Code".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpensePage."Unit of Measure Code".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            true,
            ExpensePage.Participants.Visible(),
            StrSubstNo(ParticipantActionShouldBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           false,
           ExpensePage.PerDiem.Visible(),
           StrSubstNo(PerDiemActionShouldNotBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           false,
           ExpensePage.Itemizations.Visible(),
           StrSubstNo(ItemizeActionShouldNotBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           false,
           ExpensePage."Expense Location".Editable(),
           StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Expense Location".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            true,
            ExpensePage.Amount.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpensePage.Amount.Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Amount (LCY)".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Amount (LCY)".Caption(), ExpensePage.Caption()));
    end;

    [Test]
    procedure ExpenseFieldsMustNotBeVisibleWhenRuleIsMileage()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613292] Verify that the expense fields must not be visible when Rule is Mileage.
        Initialize();

        // [GIVEN] Update Default Unit of Measure in Agent Setup.
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify Rule is Mileage.
        VerifyRuleIdInExpense(Expense, ExpenseRuleHeader);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that the expense fields are not visible when Rule is Mileage.
        Assert.AreEqual(
            false,
            ExpensePage."Starting Date and Time".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Starting Date and Time".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Ending Date and Time".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Ending Date and Time".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            true,
            ExpensePage."Starting Point".Visible(),
            StrSubstNo(FieldShouldBeVisibleErr, ExpensePage."Starting Point".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            true,
            ExpensePage."Ending Point".Visible(),
            StrSubstNo(FieldShouldBeVisibleErr, ExpensePage."Ending Point".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            true,
            ExpensePage.Mileage.Visible(),
            StrSubstNo(FieldShouldBeVisibleErr, ExpensePage.Mileage.Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            true,
            ExpensePage."Unit of Measure Code".Visible(),
            StrSubstNo(FieldShouldBeVisibleErr, ExpensePage."Unit of Measure Code".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage.Participants.Visible(),
            StrSubstNo(ParticipantActionShouldNotBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           false,
           ExpensePage.PerDiem.Visible(),
           StrSubstNo(PerDiemActionShouldNotBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           false,
           ExpensePage.Itemizations.Visible(),
           StrSubstNo(ItemizeActionShouldNotBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Expense Location".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Expense Location".Caption(), ExpensePage.Caption()));
    end;

    [Test]
    procedure ExpenseFieldsMustNotBeVisibleWhenRuleIsPerDiem()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613292] Verify that the expense fields must not be visible when Rule is Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [THEN] Verify Rule is Per Diem.
        VerifyRuleIdInExpense(Expense, ExpenseRuleHeader);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that the expense fields are not visible when Rule is Per Diem.
        Assert.AreEqual(
            true,
            ExpensePage."Starting Date and Time".Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpensePage."Starting Date and Time".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            true,
            ExpensePage."Ending Date and Time".Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpensePage."Ending Date and Time".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Starting Point".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Starting Point".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Ending Point".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Ending Point".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage.Mileage.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage.Mileage.Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Unit of Measure Code".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Unit of Measure Code".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage.Participants.Visible(),
            StrSubstNo(ParticipantActionShouldNotBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           true,
           ExpensePage.PerDiem.Visible(),
           StrSubstNo(PerDiemActionShouldBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           false,
           ExpensePage.Itemizations.Visible(),
           StrSubstNo(ItemizeActionShouldNotBeVisibleErr, ExpensePage.Caption()));
        Assert.AreEqual(
           true,
           ExpensePage."Expense Location".Editable(),
           StrSubstNo(FieldShouldBeEditableErr, ExpensePage."Expense Location".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage.Amount.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage.Amount.Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Amount (LCY)".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Amount (LCY)".Caption(), ExpensePage.Caption()));
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure CreateExpenseReportFromExpenses()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpensesPage: TestPage Expenses;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613292] Verify that Expense Report is created from Expenses.
        Initialize();

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Enqueue false to create a New Expense Report.
        LibraryVariableStorage.Enqueue(false);

        // [GIVEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Update Mileage in Expense.
        Expense.Validate(Mileage, LibraryRandom.RandDec(10, 2));
        Expense.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [WHEN] Open Expense Page.
        ExpensesPage.OpenEdit();
        ExpensesPage.GoToRecord(Expense);
        ExpensesPage."Create Expense Report".Invoke();

        // [THEN] Verify that Expense Report is created from Expenses.
        ExpenseReportHeader.Get(LibraryVariableStorage.DequeueText());

        // [THEN] Verify that Expense Report Line is created from Expense.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLine, 1);

        ExpenseReportLine.FindFirst();
        Assert.AreEqual(
            Expense."No.",
            ExpenseReportLine."Expense No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense No."), Expense."No.", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure AddExpensesInExistingExpenseReport()
    var
        Expense1: Record Expense;
        Expense2: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613292] Verify that Expenses are added in Existing Expense Report.
        Initialize();

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(150, 200);

        // [GIVEN] Enqueue false to create a New Expense Report.
        LibraryVariableStorage.Enqueue(false);

        // [GIVEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense1, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [WHEN] Update Mileage in Expense.
        Expense1.Validate(Mileage, LibraryRandom.RandDec(100, 2));
        Expense1.Modify();

        // [THEN] Verify that Rule Violation is true when Mileage is updated.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense1);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(MaxAmountErr, ExpenseRuleCondition.Value));

        // [GIVEN] Update Mileage in Expense less than Rule Amount.
        Expense1.Validate(Mileage, LibraryRandom.RandDec(10, 2));
        Expense1.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense1);

        // [WHEN] Open Expense Page.
        Expense1.SetRange("No.", Expense1."No.");
        CreateExpenseReport.AddExpensesToReport(Expense1);

        // [THEN] Verify that Expense Report is created from Expenses.
        ExpenseReportHeader.Get(LibraryVariableStorage.DequeueText());

        // [GIVEN] Enqueue true to add Expenses in Existing Expense Report.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExpenseReportHeader."No.");

        // [GIVEN] Create another Expense.
        LibraryExpense.CreateExpense(Expense2, Expense1."Expense User No.", Expense1."Expense Category", Expense1."Expense Subcategory", '', true, CurrencyCode, Amount);

        // [GIVEN] Update Mileage in Expense.
        Expense2.Validate(Mileage, LibraryRandom.RandDec(10, 2));
        Expense2.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense2);

        // [WHEN] Open Expense Page.
        Expense2.SetRange("No.", Expense2."No.");
        CreateExpenseReport.AddExpensesToReport(Expense2);

        // [THEN] Verify that Expense Report is created from Expenses.
        ExpenseReportHeader.Get(LibraryVariableStorage.DequeueText());

        // [THEN] Verify that Expense Report Line is created from both Expenses.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLine, 2);
    end;

    [Test]
    procedure ExpensesMustShowMyExpenseWhenShowOnlyMyExpensesIsExecuted()
    var
        ExpenseUser: Record "Expense User";
        Expense1: Record Expense;
        Expense2: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        CurrentUserSetup: Record "User Setup";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Expenses: TestPage Expenses;
        Amount: Decimal;
        CurrencyCode: Code[10];
        UserEmail: Text[80];
    begin
        // [SCENARIO 613292] Verify that Expenses show My Expense when "Show Only My Expenses" is executed.
        Initialize();

        // [GIVEN] Create a BC user without email.
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, CopyStr(UserId, 1, 50));

        // [GIVEN] Create a BC user with email.
        UserEmail := LibraryUtility.GenerateRandomEmail();
        CreateAndUpdateUserWithEmail(CurrentUserSetup."User ID", UserEmail);

        // [GIVEN] Create Expense User with Email.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("E-mail", UserEmail);
        ExpenseUser.Modify();

        // [GIVEN] Delete all Expenses.
        Expense1.DeleteAll(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Enqueue false to create a New Expense Report.
        LibraryVariableStorage.Enqueue(false);

        // [GIVEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense1, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create another Expense.
        LibraryExpense.CreateExpense(Expense2, ExpenseUser."No.", Expense1."Expense Category", Expense1."Expense Subcategory", '', true, CurrencyCode, Amount);

        // [WHEN] Open Expense Page and execute "Show Only My Expenses".
        Expenses.OpenEdit();
        Expenses."Show My Expenses".Invoke();

        // [THEN] Verify that only My Expense is shown when "Show Only My Expenses" is executed.
        Expenses."No.".AssertEquals(Expense2."No.");

        // [THEN] Verify that no other Expense is shown in the list.
        Assert.IsFalse(Expenses.Next(), StrSubstNo(OnlyMyExpenseExpectedErr, Expense2."No."));
    end;

    [Test]
    procedure VerifyExpensesStatisticsInExpense()
    var
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        Expense: Record Expense;
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        AmountReduction: Decimal;
    begin
        // [SCENARIO 613292] Verify that the Expenses Statistics in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', Amount);
        Expense.Validate("Merchant Name", LibraryRandom.RandText(10));
        Expense.Modify();

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Non-Refundable Amount".SetValue(AmountReduction);

        // [THEN] Verify that the Expenses Statistics in Expense.
        ExpensePage.Statistics.Amount.AssertEquals(Amount);
        ExpensePage.Statistics."Reimbursable Amount".AssertEquals(Amount - AmountReduction);
        ExpensePage.Statistics."Reimbursable Amount (LCY)".AssertEquals(Amount - AmountReduction);
        ExpensePage.Statistics."Currency Code".AssertEquals('');
        ExpensePage.Statistics."Amount (LCY)".AssertEquals(Amount);
        ExpensePage.Statistics."Expense Date".AssertEquals(WorkDate());
        ExpensePage.Statistics."Expense Category".AssertEquals(ExpenseCategory.Code);
        ExpensePage.Statistics.Description.AssertEquals(ExpenseCategory."Posting Description");
        ExpensePage.Statistics."Merchant Name".AssertEquals(Expense."Merchant Name");
        ExpensePage.Close();

        // [THEN] Verify that the Refundable Amount is reduced by Amount Reduction in Expense.
        VerifyRefundableAmount(Expense, Amount - AmountReduction, Amount - AmountReduction);
    end;

    [Test]
    procedure PaymentMethodMustBePopulatedFromExpenseCategoryInExpense()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        Expense: Record Expense;
        Amount: Decimal;
    begin
        // [SCENARIO 613292] Verify that the Payment Method is populated from Expense Category in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Validate("Default Payment Method", ExpensePaymentMethod.Code);
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Create Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', Amount);

        // [THEN] Verify that the Payment Method is populated from Expense Category in Expense.
        Assert.AreEqual(
            ExpenseCategory."Default Payment Method",
            Expense."Payment Method Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Payment Method Code"), ExpenseCategory."Default Payment Method", Expense.TableCaption()));
    end;

    [Test]
    procedure ReimbursementTypeMustBeUpdatedFromPaymentMethodInExpenseCategory()
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO 613292] Verify that the Reimbursement Type is updated from Payment Method in Expense Category.
        Initialize();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [WHEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Validate("Default Payment Method", ExpensePaymentMethod.Code);
        ExpenseCategory.Modify();

        // [THEN] Verify that the Reimbursement Type is updated from Payment Method in Expense Category.
        Assert.AreEqual(
            ExpensePaymentMethod."Reimbursement Type",
            ExpenseCategory."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, ExpenseCategory.FieldCaption("Reimbursement Type"), ExpensePaymentMethod."Reimbursement Type", ExpenseCategory.TableCaption()));
    end;

    [Test]
    procedure PaymentMethodMustBeUpdatedFromExpenseCategoryInExpense()
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        Expense: Record Expense;
        Amount: Decimal;
    begin
        // [SCENARIO 613292] Verify that the "Expense Payment Method" is updated from Expense Category in Expense.
        Initialize();

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Validate("Default Payment Method", ExpensePaymentMethod.Code);
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Create Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', Amount);

        // [THEN] Verify that the "Expense Payment Method" is updated from Expense Category in Expense.
        Assert.AreEqual(
            ExpenseCategory."Default Payment Method",
            Expense."Payment Method Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Payment Method Code"), ExpenseCategory."Default Payment Method", Expense.TableCaption()));
        Assert.AreEqual(
            ExpenseCategory.Refundable,
            Expense.Refundable,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Refundable"), ExpenseCategory.Refundable, Expense.TableCaption()));
        Assert.AreEqual(
            ExpenseCategory."Posting Description",
            Expense.Description,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Description"), ExpenseCategory."Posting Description", Expense.TableCaption()));
        Assert.AreEqual(
            ExpenseCategory."Reimbursement Type",
            Expense."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursement Type"), ExpenseCategory."Reimbursement Type", Expense.TableCaption()));
    end;

    [Test]
    procedure CanReleaseExpenseIfReimbursementTypeIsEmployeePaid()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify that Expense can be released if Reimbursement Type is Employee Paid.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [WHEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify that the Reimbursement Amount is updated when Type is Employee Paid.
        Assert.AreEqual(
            Amount,
            Expense."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount"), Amount, Expense.TableCaption()));
        Assert.AreEqual(
            Expense."Amount (LCY)",
            Expense."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount (LCY)"), Expense."Amount (LCY)", Expense.TableCaption()));
        VerifyRefundableAmount(Expense, Amount, Expense."Amount (LCY)");

        // [WHEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [THEN] Verify that Expense can be released if Reimbursement Type is Employee Paid.
        Assert.AreEqual(
            Expense.Status::Released,
            Expense.Status,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Status), Expense.Status::Released, Expense.TableCaption()));
    end;

    [Test]
    procedure CanReleaseExpenseIfReimbursementTypeIsCompanyPaid()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify that Expense can be released if Reimbursement Type is Company Paid and Payment Method Code is Blank.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [WHEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify that the Reimbursement Amount is updated when Refundable is true and Type is Employee Paid.
        Assert.AreEqual(
            Amount,
            Expense."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount"), Amount, Expense.TableCaption()));
        Assert.AreEqual(
            Expense."Amount (LCY)",
            Expense."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount (LCY)"), Expense."Amount (LCY)", Expense.TableCaption()));

        // [WHEN] Update "Reimbursement Type" in Expense.
        Expense.Validate("Reimbursement Type", Expense."Reimbursement Type"::"Company Paid");
        Expense.Validate("Payment Method Code", '');
        Expense.Modify();

        // [THEN] Verify that the Reimbursement Amount is zero when Refundable is false and Type is Company Paid.
        Assert.AreEqual(
            0,
            Expense."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount"), 0, Expense.TableCaption()));
        Assert.AreEqual(
            0,
            Expense."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount (LCY)"), 0, Expense.TableCaption()));
        VerifyRefundableAmount(Expense, Amount, Expense."Amount (LCY)");

        // [WHEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [THEN] Verify that Expense can be released if Reimbursement Type is Company Paid and Payment Method Code is Blank.
        Assert.AreEqual(
            Expense.Status::Released,
            Expense.Status,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Status), Expense.Status::Released, Expense.TableCaption()));
    end;

    [Test]
    procedure CanReleaseExpenseIfReimbursementTypeIsCreditPaid()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify that Expense can be released if Reimbursement Type is Credit Paid and Payment Method Code is Blank.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [WHEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify that the Reimbursement Amount is updated when Refundable is true and Type is Employee Paid.
        Assert.AreEqual(
            Amount,
            Expense."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount"), Amount, Expense.TableCaption()));
        Assert.AreEqual(
            Expense."Amount (LCY)",
            Expense."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount (LCY)"), Expense."Amount (LCY)", Expense.TableCaption()));
        VerifyRefundableAmount(Expense, Amount, Expense."Amount (LCY)");

        // [WHEN] Update "Reimbursement Type" in Expense.
        Expense.Validate("Reimbursement Type", Expense."Reimbursement Type"::"Credit Card");
        Expense.Validate("Payment Method Code", '');
        Expense.Modify();

        // [THEN] Verify that the Reimbursement Amount is zero when Refundable is false and Type is Credit Paid.
        Assert.AreEqual(
            0,
            Expense."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount"), 0, Expense.TableCaption()));
        Assert.AreEqual(
            0,
            Expense."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount (LCY)"), 0, Expense.TableCaption()));
        VerifyRefundableAmount(Expense, Amount, Expense."Amount (LCY)");

        // [WHEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [THEN] Verify that Expense can be released if Reimbursement Type is Credit Paid and Payment Method Code is Blank.
        Assert.AreEqual(
            Expense.Status::Released,
            Expense.Status,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Status), Expense.Status::Released, Expense.TableCaption()));
    end;

    [Test]
    procedure ReimbursementTypeMustNotBeRequiredWhenExpenseIsReleased()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify that Expense can be released if Reimbursement Type is Blank.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Update "Reimbursement Type" in Expense.
        Expense.Validate("Reimbursement Type", Expense."Reimbursement Type"::" ");
        Expense.Validate("Payment Method Code", '');
        Expense.Modify();

        // [WHEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [THEN] Verify that Expense can be released if Reimbursement Type is Blank.
        Assert.AreEqual(
            Expense.Status::Released,
            Expense.Status,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Status), Expense.Status::Released, Expense.TableCaption()));
    end;

    [Test]
    procedure ExpenseParticipantMustNotBeRequiredWhenExpenseIsReleased()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseParticipant: Record "Expense Participant";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify that Expense can be released if Expense Participant is Blank.   
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Update "Reimbursement Type" in Expense.
        Expense.Validate("Reimbursement Type", Expense."Reimbursement Type"::"Employee Paid");
        Expense.Validate("Payment Method Code", '');
        Expense.Modify();

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);
        ExpenseParticipant.Validate("Participant Employee No.", '');
        ExpenseParticipant.Modify();

        // [WHEN] Apply Rule.
        Expense.ApplyRule();

        // [THEN] Verify that Rule Violation is true when Expense Participant is Blank.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(
            StrSubstNo(
                ParticipantEmployeeMustBeRequiredInExpenseErr,
                ExpenseParticipant.FieldCaption("Participant Employee No."),
                ExpenseParticipant."Expense No.",
                ExpenseParticipant."Line No."));

        // [WHEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [THEN] Verify that Expense can be released if Expense Participant is Blank.   
        Assert.AreEqual(
            Expense.Status::Released,
            Expense.Status,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Status), Expense.Status::Released, Expense.TableCaption()));
    end;

    [Test]
    procedure ExpenseParticipantNoMustNotEditableWhenTypeIsExternal()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseParticipant: Record "Expense Participant";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseParticipantsPage: TestPage "Expense Participants";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613397] Verify that Expense Participant No. must not be editable when Type is External.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Update "Reimbursement Type" in Expense.
        Expense.Validate("Reimbursement Type", Expense."Reimbursement Type"::"Employee Paid");
        Expense.Validate("Payment Method Code", '');
        Expense.Modify();

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);
        ExpenseParticipant.Validate("Participant Type", ExpenseParticipant."Participant Type"::External);
        ExpenseParticipant.Modify();

        // [WHEN] Open Expense Participants Page.
        ExpenseParticipantsPage.OpenEdit();
        ExpenseParticipantsPage.GoToRecord(ExpenseParticipant);

        // [THEN] Verify that Expense Participant No. must not be editable when Type is External.   
        Assert.IsFalse(
            ExpenseParticipantsPage."Participant Employee No.".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseParticipantsPage."Participant Employee No.".Caption(), ExpenseParticipantsPage.Caption()));
    end;

    [Test]
    procedure ParticipantOrganizationMustFlowFromCompanyNameWhenTypeIsEmployee()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        CompanyInformation: Record "Company Information";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613397] Verify that Participant Organization must flow from Company Name when Type is Employee.
        Initialize();

        // [GIVEN] Get Company Information.
        CompanyInformation.Get();
        CompanyInformation.Validate(Name, LibraryRandom.RandText(10));
        CompanyInformation.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Update "Reimbursement Type" in Expense.
        Expense.Validate("Reimbursement Type", Expense."Reimbursement Type"::"Employee Paid");
        Expense.Validate("Payment Method Code", '');
        Expense.Modify();

        // [WHEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [THEN] Verify that Participant Organization must flow from Company Name when Type is Employee.
        Assert.AreEqual(
            CompanyInformation.Name,
            ExpenseParticipant."Participant Organization",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Organization"), CompanyInformation.Name, ExpenseParticipant.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExactMessageHandler,VerifyQuantityInExpenseItemizationsModalPageHandler')]
    procedure ExpenseItemizationQuantityValueShouldBeDefaultOne()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 615830] Verify that the Itemization Quantity must be 1 in Expense Itemization Page by default.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Store Quantity value to Library Variable Storage.
        LibraryVariableStorage.Enqueue(1);

        // [GIVEN] Enqueue expected Message text.
        LibraryVariableStorage.Enqueue(StrSubstNo(ItemizationTotalMismatchErr, 0, Expense.Amount));

        // [WHEN] Open Expense Itemization Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.Itemizations.Invoke();

        // [THEN] Verify that the Itemization Quantity must be 1 in Expense Itemization Page by default through Page Handler.
    end;

    [Test]
    procedure ExpensePerDiemAmountReductionBasedOnBreakfastLunchDinner()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePerDiem: Record "Expense Per Diem";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614319] Verify that the expense amount must be updated based on Breakfast, Lunch, Dinner selection in Expense Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get Expense Per Diem Record. 
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        ExpensePerDiem.FindFirst();

        // [WHEN] Validate Breakfast in Expense Per Diem.
        ExpensePerDiem.Validate(Breakfast, true);
        ExpensePerDiem.Modify(true);

        // [THEN] Verify Expense Amount field after Breakfast.
        VerifyExpensePerDiemAmount(Expense."No.");

        // [WHEN] Validate Lunch in Expense Per Diem.
        ExpensePerDiem.Validate(Lunch, true);
        ExpensePerDiem.Modify(true);

        // [THEN] Verify Expense Amount field after Lunch.
        VerifyExpensePerDiemAmount(Expense."No.");

        // [WHEN] Validate Dinner in Expense Per Diem.
        ExpensePerDiem.Validate(Dinner, true);
        ExpensePerDiem.Modify(true);

        // [THEN] Verify Expense Amount field after Dinner.
        VerifyExpensePerDiemAmount(Expense."No.");
    end;

    [Test]
    [HandlerFunctions('PerDiemExpensesModalPageHandler')]
    procedure ExpensePerDiemAmountReductionBasedOnLunchDinner()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614319] Verify that the expense amount must be updated based on Lunch, Dinner selection in Expense Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Store Expense No. and expected Lunch and Dinner values to Library Variable Storage.
        LibraryVariableStorage.Enqueue(Expense."No.");
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] Open Per Diem Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.PerDiem.Invoke();

        // [THEN] Verify "Per Diem Amount" field in Per Diem Page through Handler.
    end;

    [Test]
    [HandlerFunctions('PerDiemExpensesModalPageHandler')]
    procedure ExpensePerDiemAmountReductionBasedOnDinner()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614319] Verify that the expense amount must be updated based on Dinner selection in Expense Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Store Expense No. and expected Dinner values to Library Variable Storage.
        LibraryVariableStorage.Enqueue(Expense."No.");
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] Open Per Diem Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.PerDiem.Invoke();

        // [THEN] Verify "Per Diem Amount" field in Per Diem Page through Handler.
    end;

    [Test]
    [HandlerFunctions('PerDiemExpensesModalPageHandler')]
    procedure ExpensePerDiemAmountReductionBasedOnBreakfastDinner()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614319] Verify that the expense amount must be updated based on Breakfast, Dinner selection in Expense Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Store Expense No. and expected Breakfast, Dinner values to Library Variable Storage.
        LibraryVariableStorage.Enqueue(Expense."No.");
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] Open Per Diem Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.PerDiem.Invoke();

        // [THEN] Verify "Per Diem Amount" field in Per Diem Page through Handler.
    end;

    [Test]
    procedure ExpenseParticipantIsUpdatedWhenExpenseParticipantIsChangedFromEmployeeToExternal()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        CompanyInformation: Record "Company Information";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613397] Verify that Expense Participant is updated when Expense Participant is changed from Employee to External.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [WHEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [THEN] Verify that the Expense Participant is created.
        Employee.Get(ExpenseParticipant."Participant Employee No.");
        CompanyInformation.Get();
        Assert.AreEqual(
            Employee."First Name" + ' ' + Employee."Last Name",
            ExpenseParticipant."Participant Name",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Name"), Employee."First Name" + ' ' + Employee."Last Name", ExpenseParticipant.TableCaption()));
        Assert.AreEqual(
            Employee."Country/Region Code",
            ExpenseParticipant."Participant Country/Region",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Country/Region"), Employee."Country/Region Code", ExpenseParticipant.TableCaption()));
        Assert.AreEqual(
            Employee."Job Title",
            ExpenseParticipant."Participant Title",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Title"), Employee."Job Title", ExpenseParticipant.TableCaption()));
        Assert.AreEqual(
            Employee."Company E-Mail",
            ExpenseParticipant."Participant Email",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Email"), Employee."Company E-Mail", ExpenseParticipant.TableCaption()));
        Assert.AreEqual(
            CompanyInformation.Name,
            ExpenseParticipant."Participant Organization",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Organization"), CompanyInformation.Name, ExpenseParticipant.TableCaption()));

        // [WHEN] Validate Participant Type to External.
        ExpenseParticipant.Validate("Participant Type", ExpenseParticipant."Participant Type"::External);

        // [THEN] Verify that the Expense Participant fields is updated accordingly.
        Assert.AreEqual(
            '',
            ExpenseParticipant."Participant Name",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Name"), '', ExpenseParticipant.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseParticipant."Participant Country/Region",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Country/Region"), '', ExpenseParticipant.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseParticipant."Participant Title",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Title"), '', ExpenseParticipant.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseParticipant."Participant Email",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Email"), '', ExpenseParticipant.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseParticipant."Participant Organization",
            StrSubstNo(ValueMustBeEqualErr, ExpenseParticipant.FieldCaption("Participant Organization"), '', ExpenseParticipant.TableCaption()));
    end;

    [Test]
    procedure ExpenseParticipantEmployeeNoIsRequiredWhenSomeFieldsAreUpdating()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613397] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Validate "Participant Employee No." to Blank.
        ExpenseParticipant.Validate("Participant Employee No.", '');
        ExpenseParticipant.Modify();

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Update Participant Name.
        asserterror ExpenseParticipant.validate("Participant Name", LibraryRandom.RandText(10));

        // [THEN] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Assert.ExpectedTestFieldError(ExpenseParticipant.FieldCaption("Participant Employee No."), '');

        // [WHEN] Update Participant Organization.
        asserterror ExpenseParticipant.validate("Participant Organization", LibraryRandom.RandText(10));

        // [THEN] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Assert.ExpectedTestFieldError(ExpenseParticipant.FieldCaption("Participant Employee No."), '');

        // [WHEN] Update Participant Country/Region.
        asserterror ExpenseParticipant.validate("Participant Country/Region", PostCode."Country/Region Code");

        // [THEN] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Assert.ExpectedTestFieldError(ExpenseParticipant.FieldCaption("Participant Employee No."), '');

        // [WHEN] Update Participant Title.
        asserterror ExpenseParticipant.validate("Participant Title", LibraryRandom.RandText(10));

        // [THEN] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Assert.ExpectedTestFieldError(ExpenseParticipant.FieldCaption("Participant Employee No."), '');

        // [WHEN] Update Participant Email.
        asserterror ExpenseParticipant.validate("Participant Email", LibraryRandom.RandText(10));

        // [THEN] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Assert.ExpectedTestFieldError(ExpenseParticipant.FieldCaption("Participant Employee No."), '');
    end;

    [Test]
    procedure TeamManagerCanBeOnlyOneWithInExpenseUser()
    var
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: array[2] of Record "Expense User";
    begin
        // [SCENARIO 613963] Verify that the Team Manager can be only one within Expense User.
        Initialize();

        // [GIVEN] Create Expense Team.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);

        // [GIVEN] Create Expense User with Team Manager.
        LibraryExpense.CreateExpenseUser(ExpenseUser[1]);
        ExpenseUser[1].Validate("Expense Team Code", ExpenseTeam.Code);
        ExpenseUser[1].Validate("Team Manager", true);
        ExpenseUser[1].Modify();

        // [GIVEN] Create another Expense User with Team Manager.
        LibraryExpense.CreateExpenseUser(ExpenseUser[2]);
        ExpenseUser[2].Validate("Expense Team Code", ExpenseTeam.Code);
        ExpenseUser[2].Modify();

        // [WHEN] Set Team Manager to true in another Expense User.
        asserterror ExpenseUser[2].Validate("Team Manager", true);

        // [THEN] Verify that the Team Manager can be only one within Expense User.
        Assert.ExpectedError(StrSubstNo(ExistingExpenseTeamManagerErr, ExpenseUser[1]."Employee No.", ExpenseUser[2]."Expense Team Code"));
    end;

    [Test]
    procedure NumberOfTeamMemberMustBeUpdatedInExpenseTeam()
    var
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: Record "Expense User";
        ExpenseUser1: Record "Expense User";
    begin
        // [SCENARIO 613963] Verify that the "Number Of Team Members" must be updated in Expense Team.
        Initialize();

        // [GIVEN] Create Expense Team.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);

        // [GIVEN] Create Expense User with Team Manager.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("Expense Team Code", ExpenseTeam.Code);
        ExpenseUser.Validate("Team Manager", true);
        ExpenseUser.Modify();

        // [WHEN] Create another Expense User with Team Manager.
        LibraryExpense.CreateExpenseUser(ExpenseUser1);
        ExpenseUser1.Validate("Expense Team Code", ExpenseTeam.Code);
        ExpenseUser1.Modify();

        // [THEN] Verify that the "Number Of Team Members" is updated in Expense Team.
        ExpenseTeam.CalcFields("Number Of Team Members");
        Assert.AreEqual(
            2,
            ExpenseTeam."Number Of Team Members",
            StrSubstNo(ValueMustBeEqualErr, ExpenseTeam.FieldCaption("Number Of Team Members"), 2, ExpenseTeam.TableCaption()));
    end;

    // [Test] // Disabled - will be re-enabled in work item 629484
    procedure EntraIdMustBeRequiredInExpenseUserWhenExpenseApprovalSetupIsCreated()
    var
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: Record "Expense User";
        ExpenseUser1: Record "Expense User";
        ExpenseUserPage: TestPage "Expense User";
        UserName: Text[50];
        UserEmail: Text[80];
    begin
        // [SCENARIO 580730] Verify that the Entra ID must be required in Expense User when Expense Approval Setup is created.
        Initialize();

        // [GIVEN] Enable SaaS feature.
        EnableSaaS(true);

        // [GIVEN] Create a BC user with email.
        UserName := CopyStr(LibraryRandom.RandText(50), 1, 50);
        UserEmail := UserName + '@' + 'example.com';
        CreateUserWithEmail(UserName, UserEmail);

        // [GIVEN] Create Expense Team.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);

        // [GIVEN] Create Expense User with Team Manager.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("E-mail", UserEmail);
        ExpenseUser.Validate("Can Approve", true);
        ExpenseUser.Validate("Expense Team Code", ExpenseTeam.Code);
        ExpenseUser.Validate("Team Manager", true);
        ExpenseUser.Modify();

        // [GIVEN] Create another Expense User with Team Manager.
        LibraryExpense.CreateExpenseUser(ExpenseUser1);
        ExpenseUser1.Validate("Expense Team Code", ExpenseTeam.Code);
        ExpenseUser1.Modify();

        // [WHEN] Open Expense Approval Setup page from another Expense User.
        ExpenseUserPage.OpenEdit();
        ExpenseUserPage.GoToRecord(ExpenseUser1);
        asserterror ExpenseUserPage.ApprovalSetup.Invoke();

        // [THEN] Verify that the Entra ID must be required in Expense User when Expense Approval Setup is created.
        Assert.ExpectedTestFieldError(ExpenseUser.FieldCaption("Entra ID"), '');
    end;

    [Test]
    [HandlerFunctions('ExpenseApprovalSetupPageHandler')]
    procedure ApproverIDOfTeamManagerMustBeAutomaticallyFlowInExpenseApprovalSetup()
    var
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: Record "Expense User";
        ExpenseUser1: Record "Expense User";
        ExpenseUserPage: TestPage "Expense User";
        UserName: Text[50];
        UserEmail: Text[80];
    begin
        // [SCENARIO 580730] Verify that the Approver ID of Team Manager must be automatically flow in Expense Approval Setup.
        Initialize();

        // [GIVEN] Create a BC user with email.
        UserName := CopyStr(LibraryRandom.RandText(50), 1, 50);
        UserEmail := UserName + '@' + 'example.com';
        CreateUserWithEmail(UserName, UserEmail);

        // [GIVEN] Create Expense Team.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);

        // [GIVEN] Create Expense User with Team Manager.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("E-mail", UserEmail);
        ExpenseUser.Validate("Can Approve", true);
        ExpenseUser.Validate("Expense Team Code", ExpenseTeam.Code);
        ExpenseUser.Validate("Team Manager", true);
        ExpenseUser.Modify();

        // [GIVEN] Create another Expense User with Team Manager.
        LibraryExpense.CreateExpenseUser(ExpenseUser1);
        ExpenseUser1.Validate("Entra Id", DelChr(ExpenseUser.SystemId, '=', '{}'));
        ExpenseUser1.Validate("Expense Team Code", ExpenseTeam.Code);
        ExpenseUser1.Modify();

        // [WHEN] Open Expense Approval Setup page from another Expense User.
        LibraryVariableStorage.Enqueue(ExpenseUser."No.");
        ExpenseUserPage.OpenEdit();
        ExpenseUserPage.GoToRecord(ExpenseUser1);
        ExpenseUserPage.ApprovalSetup.Invoke();

        // [THEN] Verify that the Approver ID of Team Manager must be automatically flow in Expense Approval Setup Through Handler.
    end;

    [Test]
    [HandlerFunctions('ExpectedConfirmHandler')]
    procedure CanOverwriteEmployeeInformationInExpenseUser()
    var
        Employee: Record Employee;
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: Record "Expense User";
        ExpenseUser1: Record "Expense User";
        UserName: Text[50];
        UserEmail: Text[80];
    begin
        // [SCENARIO 580730] Verify that the Employee Information can be overwritten in Expense User.
        Initialize();

        // [GIVEN] Create a BC user with email.
        UserName := CopyStr(LibraryRandom.RandText(50), 1, 50);
        UserEmail := UserName + '@' + 'example.com';
        CreateUserWithEmail(UserName, UserEmail);

        // [GIVEN] Create Expense Team.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);

        // [GIVEN] Create Employee.
        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate("Company E-Mail", UserEmail);
        Employee.Modify();

        // [GIVEN] Create Expense User with Team Manager.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("E-mail", UserEmail);
        ExpenseUser.Validate("Can Approve", true);
        ExpenseUser.Validate("Expense Team Code", ExpenseTeam.Code);
        ExpenseUser.Validate("Team Manager", true);
        ExpenseUser.Modify();

        // [GIVEN] Create another Expense User with Team Manager.
        LibraryExpense.CreateExpenseUser(ExpenseUser1);

        // [WHEN] Overwrite Employee Information in another Expense User.
        LibraryVariableStorage.Enqueue(StrSubstNo(CanOverwriteEmployeeInformationQst, Employee."No."));
        ExpenseUser.Validate("Employee No.", Employee."No.");

        // [THEN] Verify that the Employee Information is overwritten in Expense User.
        Assert.AreEqual(
            Employee.FullName(),
            ExpenseUser.Name,
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption(Name), Employee.FullName(), ExpenseUser.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('PerDiemExpensesWithRuleModalPageHandler')]
    procedure FieldsAreEditableAndNonEditableInExpensePerDiemPage()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616946] Verify that the some fields are editable and non-editable in Expense Per Diem Page When Rule is applied.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [WHEN] Open Per Diem Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.PerDiem.Invoke();

        // [THEN] Verify that the some fields are editable and non-editable in Expense Per Diem Page When Rule is applied through Handler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,NewPerDiemExpensesWithRuleModalPageErrorHandler')]
    procedure NewPerDiemEntryCannotBeCreatedWhenRuleIsAppliedFromExpensePerDiemPage()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616946] Verify that the new Per Diem entry cannot be created when Rule is applied from Expense Per Diem Page.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [WHEN] Open Per Diem Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.PerDiem.Invoke();

        // [THEN] Verify that the new Per Diem entry cannot be created when Rule is applied from Expense Per Diem Page through Handler.
    end;

    [Test]
    [HandlerFunctions('PerDiemExpensesWithNoRuleModalPageHandler')]
    procedure FieldsAreEditableInExpensePerDiemPage()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616946] Verify that the some fields are editable in Expense Per Diem Page When Rule is not applied.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with No Rule for "Per Diem".
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::"Per Diem", "Expense Attachment Enforcement"::" ", true, CurrencyCode, Amount);

        // [WHEN] Open Per Diem Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.PerDiem.Invoke();

        // [THEN] Verify that the fields are editable in Expense Per Diem Page When Rule is not applied through Handler.
    end;

    [Test]
    [HandlerFunctions('NewPerDiemExpensesWithNoRuleModalPageErrorHandler')]
    procedure NewPerDiemEntryCannotBeCreatedWhenRuleIsNotAppliedFromExpensePerDiemPage()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePerDiem: Record "Expense Per Diem";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616946] Verify that the new Per Diem entry cannot be created when Rule is not applied from Expense Per Diem Page.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with No Rule for "Per Diem".
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::"Per Diem", "Expense Attachment Enforcement"::" ", true, CurrencyCode, Amount);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open Per Diem Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.PerDiem.Invoke();

        // [THEN] Verify that the new Per Diem entry cannot be created when Rule is not applied from Expense Per Diem Page through Handler.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpensePerDiem, 0);
    end;

    [Test]
    procedure DocumentAttachmentIsShownOnExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613390] Verify that Document Attachment is shown on Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(Expense);
        CreateDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + JPEGLbl);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Document Attachment is shown on Expense.
        ExpensePage."Attached Documents List".Name.AssertEquals(Expense."No.");
        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::Expense, Expense."No.", 0),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, Expense.TableCaption()));
    end;

    [Test]
    procedure DocumentAttachmentIsDeletedWhenExpenseIsDeleted()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        DocumentAttachment: Record "Document Attachment";
        ExpensePerDiem: Record "Expense Per Diem";
        RecRef: RecordRef;
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613390] Verify that Document Attachment is deleted when Expense is deleted.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(Expense);
        CreateDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + JPEGLbl);

        // [GIVEN] Delete Expense Per Diem.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        ExpensePerDiem.DeleteAll();

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Document Attachment is shown on Expense.
        ExpensePage."Attached Documents List".Name.AssertEquals(Expense."No.");

        // [WHEN] Delete Expense.
        Expense.Delete(true);

        // [THEN] Verify that Document Attachment is deleted when Expense is deleted.
        DocumentAttachment.SetRange("Table ID", Database::Expense);
        DocumentAttachment.SetRange("No.", Expense."No.");
        Assert.RecordCount(DocumentAttachment, 0);
    end;

    [Test]
    procedure CannotSelectInactiveExpenseCategoryInExpense()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617001] Verify that inactive Expense Category cannot be selected in Expense.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, "Expense Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");

        // [GIVEN] Set Expense Category as Inactive.
        ExpenseCategory.Validate(Inactive, true);
        ExpenseCategory.Modify(true);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [WHEN] Try to create Expense with inactive Category.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", '', '', '', true, CurrencyCode, Amount);
        asserterror Expense.Validate("Expense Category", ExpenseCategory.Code);

        // [THEN] Verify that inactive Expense Category cannot be selected in Expense.
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    procedure CannotSelectInactiveExpenseSubcategoryInExpense()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617001] Verify that inactive Expense Subcategory cannot be selected in Expense.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category and Expense Subcategory.
        LibraryExpense.CreateExpenseCategoryWithSubCategory(ExpenseCategory, "Expense Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ", true);
        ExpenseSubCategory.SetRange("Expense Category Code", ExpenseCategory.Code);
        ExpenseSubCategory.FindFirst();

        // [GIVEN] Set Expense Subcategory as Inactive.
        ExpenseSubCategory.Validate(Inactive, true);
        ExpenseSubCategory.Modify(true);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [WHEN] Create Expense with Category and try to select inactive Subcategory.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, CurrencyCode, Amount);
        asserterror Expense.Validate("Expense Subcategory", ExpenseSubCategory.Code);

        // [THEN] Verify that inactive Expense Subcategory cannot be selected in Expense.
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    procedure CannotCreateItemizationWithInactiveExpenseSubcategory()
    var
        Expense: Record Expense;
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseItemization: Record "Expense Itemization";
        PostCode: Record "Post Code";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617001] Verify that itemization cannot be created for expense with inactive Expense Subcategory.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Subcategory and assign to expense.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);
        Expense.Validate("Expense Subcategory", ExpenseSubCategory.Code);
        Expense.Modify(true);

        // [GIVEN] Set Expense Subcategory as Inactive.
        ExpenseSubCategory.Validate(Inactive, true);
        ExpenseSubCategory.Modify(true);

        // [WHEN] Try to create Expense Itemization.
        asserterror LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, Expense."Expense Category", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [THEN] Verify that itemization cannot be created for expense with inactive Expense Subcategory.
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('CreateExpenseItemizationsWithSubCategoryHandler')]
    procedure AmountReductionIsUpdatedInExpenseFromExpenseItemizationPage()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseSubCategory: array[2] of Record "Expense SubCategory";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        AmountReduction: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616971] Verify that the Amount Reduction is updated in Expense from Expense Itemization Page.
        // when Expense Itemization is created with Refundable and Non-Refundable Expense Sub Category.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandIntInRange(50, 90);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Sub Category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[1], Expense."Expense Category", true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[2], Expense."Expense Category", false);

        // [GIVEN] Enqueue Expense Sub Category Code, Quantity and Amount for Expense Itemization.
        LibraryVariableStorage.Enqueue(ExpenseSubCategory[1].Code);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(Amount - AmountReduction);

        LibraryVariableStorage.Enqueue(ExpenseSubCategory[2].Code);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(AmountReduction);

        // [WHEN] Open Expense Itemization Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.Itemizations.Invoke();

        // [THEN] Verify that the Non-Refundable Amount is updated in Expense from Expense Itemization Page.
        ExpensePage."Non-Refundable Amount".AssertEquals(AmountReduction);
        ExpensePage.Close();

        // [THEN] Verify that the Refundable Amount is reduced by Amount Reduction in Expense.
        Expense.Get(Expense."No.");
        VerifyRefundableAmount(Expense, Amount - AmountReduction, Expense."Reimbursable Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ExactMessageHandler,VerifyQuantityInExpenseItemizationsModalPageHandler')]
    procedure ItemizationTotalReductionMismatchInExpenseAndExpenseItemization()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseItemization: array[2] of Record "Expense Itemization";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        AmountReduction: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616971] Verify that the Itemization Total Reduction Mismatch error is shown in Expense and Expense Itemization.
        // when Expense Itemization is created with Refundable and Non-Refundable Expense Sub Category
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandIntInRange(50, 90);

        // [GIVEN] Create Expense with Itemization.
        CreateExpenseWithRefundableAndNonRefundableItemization(Expense, ExpenseItemization, ExpenseRuleHeader, ExpenseRuleCondition, true, CurrencyCode, Amount, Amount - AmountReduction, AmountReduction - 1);

        // [GIVEN] Enqueue expected Message text.
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(StrSubstNo(ItemizationTotalMismatchErr, Amount - 1, Expense.Amount));

        // [GIVEN] Update Non-Refundable Amount in Expense which is mismatch with total reduction in Itemization.
        Expense."Non-Refundable Amount" := AmountReduction;
        Expense.UpdateAmount();
        Expense.Modify();

        // [WHEN] Open Expense Itemization Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.Itemizations.Invoke();

        // [THEN] Verify that the Itemization Total Mismatch error in rule violation.
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(ItemizationTotalMismatchErr, Amount - 1, Expense.Amount));
        ExpensePage.RuleViolations.Next();
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(ItemizationTotalReductionMismatchErr, AmountReduction - 1, Expense."Non-Refundable Amount"));

        // [THEN] Verify that the Non-Refundable Amount field is non-editable in Expense Page.
        Assert.AreEqual(
            false,
            ExpensePage."Non-Refundable Amount".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Non-Refundable Amount".Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Amount (LCY)".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Amount (LCY)".Caption(), ExpensePage.Caption()));

        // [THEN] Verify that the Amount is editable in Expense Page.
        Assert.AreEqual(
            true,
            ExpensePage.Amount.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpensePage.Amount.Caption(), ExpensePage.Caption()));

        // [THEN] Verify that the Refundable Amount is reduced by Amount Reduction in Expense.
        VerifyRefundableAmount(Expense, Amount - AmountReduction, Expense."Reimbursable Amount (LCY)");
    end;

    [Test]
    procedure RefundableMustBeTrueInExpenseWhenNonRefundableAmountIsUpdatedInExpenseItemization()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseItemization: array[2] of Record "Expense Itemization";
        Amount: Decimal;
        AmountReduction: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616971] Verify that the Refundable must be true in Expense when Non-Refundable Amount is updated in Expense Itemization.
        // when Expense Itemization is created with Refundable and Non-Refundable Expense Sub Category
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandIntInRange(50, 90);

        // [WHEN] Create Expense with Itemization.
        asserterror CreateExpenseWithRefundableAndNonRefundableItemization(Expense, ExpenseItemization, ExpenseRuleHeader, ExpenseRuleCondition, false, CurrencyCode, Amount, Amount - AmountReduction, AmountReduction - 1);

        // [THEN] Verify that the Refundable must be true in Expense when Non-Refundable Amount is updated in Expense Itemization.
        Assert.ExpectedTestFieldError(Expense.FieldCaption("Refundable"), Format(true));
    end;

    [Test]
    procedure StatusMustBeOpenInExpenseIfItemizationIsUpdated()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseItemization: array[2] of Record "Expense Itemization";
        Amount: Decimal;
        AmountReduction: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616971] Verify that the Status must be Open in Expense if Itemization is updated.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(50, 60);
        AmountReduction := LibraryRandom.RandIntInRange(10, 15);

        // [GIVEN] Create Expense with Itemization.
        CreateExpenseWithRefundableAndNonRefundableItemization(Expense, ExpenseItemization, ExpenseRuleHeader, ExpenseRuleCondition, true, CurrencyCode, Amount, Amount - AmountReduction, AmountReduction);

        // [GIVEN] Release Expense.
        Expense.Get(Expense."No.");
        Expense.PerformManualRelease();

        // [WHEN] Validate Description in Expense Itemization.
        asserterror ExpenseItemization[1].Validate(Description, LibraryRandom.RandText(10));

        // [THEN] Verify that the Status is Open if Itemization is updated.
        Assert.ExpectedTestFieldError(Expense.FieldCaption(Status), Format(Expense.Status::Open));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RuleViolationIsShownWhenAttachmentIsMandatory()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617011] Verify that Rule Violation is shown when Attachment is mandatory in Expense Category.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", "Expense Attachment Enforcement"::Error, '',
            ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Rule Violation is shown on Expense due to Attachment is mandatory.
        ExpensePage.GoToRecord(Expense);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(ExpenseDocumentAttachmentMandatoryMsg, Expense."No."));
        ExpensePage.Close();

        // [GIVEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(Expense);
        CreateDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + JPEGLbl);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Document Attachment is shown on Expense.
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Attached Documents List".Name.AssertEquals(Expense."No.");
        VerifyReceiptIsAttached(Expense."No.", true, DocumentAttachment.ID);
        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::Expense, Expense."No.", 0),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, Expense.TableCaption()));

        // [THEN] Verify that No Rule Violation is shown on Expense after adding Attachment.
        ExpensePage.RuleViolations.Description.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RuleViolationIsShownWhenAttachmentIsMandatoryWithNoRule()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePerDiem: Record "Expense Per Diem";
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617011] Verify that Rule Violation is shown when Attachment is mandatory in Expense Category without Rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with No Rule for "Per Diem".
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::"Per Diem", "Expense Attachment Enforcement"::Error, true, CurrencyCode, Amount);

        // [GIVEN] Create Per Diem for Expense.
        LibraryExpense.CreateExpensePerDiem(ExpensePerDiem, Expense, Expense."Expense Category", Expense."Expense Subcategory", Expense."Expense Location", WorkDate(), true, true, true, Amount);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Rule Violation is shown on Expense due to Attachment is mandatory.
        ExpensePage.GoToRecord(Expense);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(ExpenseDocumentAttachmentMandatoryMsg, Expense."No."));
        ExpensePage.Close();

        // [GIVEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(Expense);
        CreateDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + JPEGLbl);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Document Attachment is shown on Expense.
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Attached Documents List".Name.AssertEquals(Expense."No.");
        VerifyReceiptIsAttached(Expense."No.", true, DocumentAttachment.ID);
        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::Expense, Expense."No.", 0),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, Expense.TableCaption()));

        // [THEN] Verify that No Rule Violation is shown on Expense after adding Attachment.
        ExpensePage.RuleViolations.Description.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler,ConfirmHandler')]
    procedure WarningIsShownWhenAttachmentEnforcementIsWarning()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
    begin
        // [SCENARIO 617011] Verify that Warning is shown when Attachment Enforcement is Warning in Expense Category.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", "Expense Attachment Enforcement"::Warning, '',
            ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Warning is shown on Expense due to Attachment Enforcement being Warning.
        ExpensePage.GoToRecord(Expense);
        ExpensePage.RuleViolations.Description.AssertEquals('');
        VerifyExpenseNotification(Expense."No.");

        // [WHEN] Release Expense.
        ExpensePage.Release.Invoke();

        // [THEN] Verify Expense is Released Successfully.
        ExpensePage.Status.AssertEquals(Format(Expense.Status::Released));
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler,ConfirmHandler')]
    procedure WarningIsShownWhenAttachmentEnforcementIsWarningWithNoRule()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePerDiem: Record "Expense Per Diem";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617011] Verify that Warning is shown when Attachment Enforcement is Warning in Expense Category with no Rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with No Rule for "Per Diem".
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::"Per Diem", "Expense Attachment Enforcement"::Warning, true, CurrencyCode, Amount);

        // [GIVEN] Create Per Diem for Expense.
        LibraryExpense.CreateExpensePerDiem(ExpensePerDiem, Expense, Expense."Expense Category", Expense."Expense Subcategory", Expense."Expense Location", WorkDate(), true, true, true, Amount);

        // [GIVEN] Apply Rule for Expense.
        Expense.ApplyRule();

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Warning is shown on Expense due to Attachment Enforcement being Warning.
        ExpensePage.GoToRecord(Expense);
        ExpensePage.RuleViolations.Description.AssertEquals('');
        VerifyExpenseNotification(Expense."No.");

        // [WHEN] Release Expense.
        ExpensePage.Release.Invoke();

        // [THEN] Verify Expense is Released Successfully.
        ExpensePage.Status.AssertEquals(Format(Expense.Status::Released));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReceiptAttachedIsUpdatedWhenAttachmentIsDeletedFromExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617011] Verify that Receipt Attached is updated when Attachment is deleted from Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", "Expense Attachment Enforcement"::Error, '',
            ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [WHEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(Expense);
        CreateDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + JPEGLbl);

        // [THEN] Verify that Receipt is attached to Expense.
        VerifyReceiptIsAttached(Expense."No.", true, DocumentAttachment.ID);

        // [WHEN] Delete Document Attachment from Expense.
        DocumentAttachment.Delete(true);

        // [THEN] Verify that Receipt is attached to Expense.
        VerifyReceiptIsAttached(Expense."No.", false, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReceiptAttachedIsUpdatedWhenAttachmentIsDeletedFromExpenseWithNoRule()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617011] Verify that Receipt Attached is updated when Attachment is deleted from Expense with no Rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with No Rule for "Per Diem".
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::"Per Diem", "Expense Attachment Enforcement"::Error, true, CurrencyCode, Amount);

        // [WHEN] Create Document Attachment with JPEG image.
        RecRef.GetTable(Expense);
        CreateDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + JPEGLbl);

        // [THEN] Verify that Receipt is attached to Expense.
        VerifyReceiptIsAttached(Expense."No.", true, DocumentAttachment.ID);

        // [WHEN] Delete Document Attachment from Expense.
        DocumentAttachment.Delete(true);

        // [THEN] Verify that Receipt is attached to Expense.
        VerifyReceiptIsAttached(Expense."No.", false, 0);
    end;

    [Test]
    procedure ReimbursementTypeMustNotBeEditableInExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616954] Verify that the reimbursement type must not be editable.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that the reimbursement type is not editable in Expense Page.
        Assert.AreEqual(
            false,
            ExpensePage."Reimbursement Type".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Reimbursement Type".Caption(), ExpensePage.Caption()));

        // [THEN] Verify that the Amount and "Amount (LCY) is not editable in Expense Page.
        Assert.AreEqual(
            false,
            ExpensePage.Amount.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage.Amount.Caption(), ExpensePage.Caption()));
        Assert.AreEqual(
            false,
            ExpensePage."Amount (LCY)".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePage."Amount (LCY)".Caption(), ExpensePage.Caption()));
    end;

    [Test]
    procedure PDFPreviewFactboxIsVisibleOnExpenseCardWhenPDFAttached()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        ExpensePage: TestPage Expense;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621724] PDF Preview factbox is visible on Expense card when PDF attachment exists.
        Initialize();

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(100));

        // [GIVEN] Create PDF Document Attachment for Expense.
        RecRef.GetTable(Expense);
        CreatePDFDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + PDFLbl);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that PDF Preview factbox is visible on Expense card.
        Assert.IsTrue(
            ExpensePage."Expense Picture".Visible(),
            StrSubstNo(PDFPreviewShouldBeVisibleErr, ExpensePage.Caption));
    end;

    [Test]
    procedure PDFPreviewFactboxIsHiddenOnExpenseCardWhenNoPDFAttached()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        ExpensePage: TestPage Expense;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621724] PDF Preview factbox is hidden on Expense card when no PDF attachment exists.
        Initialize();

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(100));

        // [WHEN] Create JPEG Document Attachment for Expense.
        RecRef.GetTable(Expense);
        CreateDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + JPEGLbl);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that PDF Preview factbox is not visible on Expense card.
        Assert.IsFalse(
            ExpensePage."Expense Picture".Visible(),
            StrSubstNo(PDFPreviewShouldNotBeVisibleErr, ExpensePage.Caption));
    end;

    [Test]
    procedure PDFPreviewFactboxIsHiddenOnExpenseCardAfterDeletingPDF()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        ExpensePage: TestPage Expense;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621724] PDF Preview factbox is hidden after deleting PDF attachment from expense.
        Initialize();

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(100));

        // [WHEN] Create PDF Document Attachment for Expense.
        RecRef.GetTable(Expense);
        CreatePDFDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + PDFLbl);

        // [THEN] Open Expense Page and verify PDF Preview factbox is visible.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        Assert.IsTrue(
            ExpensePage."Expense Picture".Visible(),
            StrSubstNo(PDFPreviewShouldBeVisibleErr, ExpensePage.Caption));
        ExpensePage.Close();

        // [GIVEN] Delete PDF Document Attachment from Expense.
        DocumentAttachment.Delete(true);

        // [WHEN] Re-open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that PDF Preview factbox is no longer visible.
        Assert.IsFalse(
            ExpensePage."Expense Picture".Visible(),
            StrSubstNo(PDFPreviewShouldNotBeVisibleErr, ExpensePage.Caption));
    end;

    [Test]
    procedure PDFPreviewFactboxIsVisibleOnExpensesListWhenPDFAttached()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        ExpensesPage: TestPage Expenses;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621724] PDF Preview factbox is visible on Expenses list when PDF attachment exists.
        Initialize();

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(100));

        // [WHEN] Create PDF Document Attachment for Expense.
        RecRef.GetTable(Expense);
        CreatePDFDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + PDFLbl);

        // [WHEN] Open Expenses list Page.
        ExpensesPage.OpenView();
        ExpensesPage.GoToRecord(Expense);

        // [THEN] Verify that PDF Preview factbox is visible on Expenses list.
        Assert.IsTrue(
            ExpensesPage."Expense Picture".Visible(),
            StrSubstNo(PDFPreviewShouldBeVisibleErr, ExpensesPage.Caption));
    end;

    [Test]
    procedure HasPDFAttachmentReturnsTrueWhenExpenseHasPDFAttachment()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        ExpenseAttachmentMgt: Codeunit "Expense Attachment Mgt.";
        RecRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621724] HasPDFAttachment returns true when expense has a PDF attachment.
        Initialize();

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(100));

        // [WHEN] Create PDF Document Attachment for Expense.
        RecRef.GetTable(Expense);
        CreatePDFDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + PDFLbl);

        // [THEN] Check if Expense has PDF attachment.
        Assert.IsTrue(
            ExpenseAttachmentMgt.HasPDFAttachment(Database::Expense, Expense."No.", 0),
            HasPDFAttachmentShouldBeTrueErr);
    end;

    [Test]
    procedure HasPDFAttachmentReturnsFalseWhenExpenseHasJPEGAttachment()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        ExpenseAttachmentMgt: Codeunit "Expense Attachment Mgt.";
        RecRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621724] HasPDFAttachment returns false when expense has only JPEG attachment
        Initialize();

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(100));

        // [WHEN] Create JPEG Document Attachment for Expense.
        RecRef.GetTable(Expense);
        CreateDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + JPEGLbl);

        // [THEN] Check if Expense has PDF attachment.
        Assert.IsFalse(
            ExpenseAttachmentMgt.HasPDFAttachment(Database::Expense, Expense."No.", 0),
            HasPDFAttachmentShouldBeFalseErr);
    end;

    [Test]
    procedure HasPDFAttachmentReturnsFalseAfterDeletingPDFFromExpense()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        ExpenseAttachmentMgt: Codeunit "Expense Attachment Mgt.";
        RecRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621724] HasPDFAttachment returns false after deleting PDF attachment from expense.
        Initialize();

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(100));

        // [WHEN] Create PDF Document Attachment for Expense.
        RecRef.GetTable(Expense);
        CreatePDFDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + PDFLbl);

        // [GIVEN] Delete PDF Document Attachment from Expense.
        DocumentAttachment.Delete(true);

        // [THEN] HasPDFAttachment returns false.
        Assert.IsFalse(
            ExpenseAttachmentMgt.HasPDFAttachment(Database::Expense, Expense."No.", 0),
            HasPDFAttachmentShouldBeFalseErr);
    end;

    [Test]
    procedure HasPDFAttachmentReturnsTrueForExpenseReportLine()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        DocumentAttachment: Record "Document Attachment";
        ExpenseAttachmentMgt: Codeunit "Expense Attachment Mgt.";
        RecRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621724] HasPDFAttachment returns true when expense report line has a PDF attachment.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, "Expense Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");

        // [GIVEN] Create Expense Report for Expense User.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Expense Report Line on Expense Report.
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', LibraryRandom.RandInt(100));

        // [WHEN] Create PDF Document Attachment for Expense Report Line.
        RecRef.GetTable(ExpenseReportLine);
        CreatePDFDocumentAttachment(DocumentAttachment, RecRef, ExpenseReportLine."Document No." + PDFLbl);

        // [THEN] Check if Expense Report Line has PDF attachment.
        Assert.IsTrue(
            ExpenseAttachmentMgt.HasPDFAttachment(Database::"Expense Report Line", ExpenseReportLine."Document No.", ExpenseReportLine."Line No."),
            HasPDFAttachmentShouldBeTrueErr);
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryVariableStorage.Clear();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        Workflow.DeleteAll();
        IsInitialized := true;

        Commit(); // Ensure setup data is committed before running tests. The first test is expected to fail and it rolls back the changes made after early exit on IsInitialized check.

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Test");
    end;

    local procedure CreateExpense(var Expense: Record Expense; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', Refundable, CurrencyCode, Amount);
    end;

    local procedure CreateExpenseWithNoRule(var Expense: Record Expense; ExpenseDetailRequired: Enum "Expense Detail Needed"; AttachmentEnforcement: Enum "Expense Attachment Enforcement"; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        PostCode: Record "Post Code";
        ExpenseLocation: Record "Expense Location";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseDetailRequired);

        UpdateAttachmentEnforcementInExpenseCategory(ExpenseCategory.Code, AttachmentEnforcement);

        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', ExpenseLocation."No.", Refundable, CurrencyCode, Amount);
    end;

    local procedure CreateExpenseWithRule(
        var Expense: Record Expense;
        var ExpenseRuleHeader: Record "Expense Rule Header";
        var ExpenseRuleCondition: Record "Expense Rule Condition";
        CountryRegionCode: Code[10];
        City: Text[30];
        CurrencyCode: Code[10];
        Amount: Decimal;
        EffectiveDate: Date;
        ExpenseDetailRequired: Enum "Expense Detail Needed";
        JustificationRequired: Enum "Expense Justification";
        UnitOfMeasureCode: Code[10];
        ConditionType: Enum "Expense Rule Condition Type";
        Refundable: Boolean;
        Value: Decimal)
    begin
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, CountryRegionCode, City, CurrencyCode, Amount, EffectiveDate,
            ExpenseDetailRequired, JustificationRequired, "Expense Attachment Enforcement"::" ", UnitOfMeasureCode, ConditionType, Refundable, Value);
    end;

    local procedure CreateExpenseWithRule(
        var Expense: Record Expense;
        var ExpenseRuleHeader: Record "Expense Rule Header";
        var ExpenseRuleCondition: Record "Expense Rule Condition";
        CountryRegionCode: Code[10];
        City: Text[30];
        CurrencyCode: Code[10];
        Amount: Decimal;
        EffectiveDate: Date;
        ExpenseDetailRequired: Enum "Expense Detail Needed";
        JustificationRequired: Enum "Expense Justification";
        AttachmentEnforcement: Enum "Expense Attachment Enforcement";
        UnitOfMeasureCode: Code[10];
        ConditionType: Enum "Expense Rule Condition Type";
        Refundable: Boolean;
        Value: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseUser: Record "Expense User";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseDetailRequired);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        UpdateAttachmentEnforcementInExpenseCategory(ExpenseCategory.Code, AttachmentEnforcement);
        if ExpenseDetailRequired = "Expense Detail Needed"::"Per Diem" then begin
            LibraryExpense.CreateExpenseLocation(ExpenseLocation, CountryRegionCode, City);
            LibraryExpense.CreateExpenseRuleWithCondition(
                ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", EffectiveDate,
                JustificationRequired, CurrencyCode, UnitOfMeasureCode, ConditionType, Value);

            LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, ExpenseLocation."No.", Refundable, CurrencyCode, Amount);
            Expense.Validate("Starting Date and Time", CreateDateTime(EffectiveDate, Time));
            Expense.Validate("Ending Date and Time", CreateDateTime(EffectiveDate, Time));
            Expense.Modify();
        end else begin
            LibraryExpense.CreateExpenseRuleWithCondition(
                ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', EffectiveDate,
                JustificationRequired, CurrencyCode, UnitOfMeasureCode, ConditionType, Value);

            LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', Refundable, CurrencyCode, Amount);
        end;
    end;

    local procedure UpdateAttachmentEnforcementInExpenseCategory(CategoryCode: Code[20]; AttachmentEnforcement: Enum "Expense Attachment Enforcement")
    var
        ExpenseCategory: Record "Expense Category";
    begin
        ExpenseCategory.Get(CategoryCode);
        ExpenseCategory.Validate("Attachment Enforcement", AttachmentEnforcement);
        ExpenseCategory.Modify(true);
    end;

    local procedure CreateDimSetIDFromDimValue(var DimSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionMgt: Codeunit DimensionManagement;
    begin
        if DimSetID <> 0 then
            DimensionMgt.GetDimensionSet(TempDimSetEntry, DimSetID);

        TempDimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        if not TempDimSetEntry.Insert() then
            TempDimSetEntry.Modify();

        DimSetID := DimensionMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    local procedure VerifyRuleIdInExpense(Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        Assert.AreEqual(
            ExpenseRuleHeader.SystemId,
            Expense."Applied Rule Id",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Applied Rule Id"), ExpenseRuleHeader.SystemId, Expense.TableCaption()));
    end;

    local procedure UpdateReductionForMealPerDiem(Breakfast: Decimal; Lunch: Decimal; Dinner: Decimal)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Reduction for Breakfast %", Breakfast);
        ExpenseAgentSetup.Validate("Reduction for Lunch %", Lunch);
        ExpenseAgentSetup.Validate("Reduction for Dinner %", Dinner);
        ExpenseAgentSetup.Modify();
    end;

    local procedure VerifyExpensePerDiemAmount(ExpenseNo: Code[20])
    var
        Expense: Record Expense;
    begin
        Expense.Get(ExpenseNo);
        Assert.AreEqual(
            CalculateAmountReduction(Expense."No."),
            Expense."Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Amount"), CalculateAmountReduction(Expense."No."), Expense.TableCaption()));
    end;

    local procedure CalculateAmountReduction(ExpenseNo: Code[20]): Decimal
    var
        Expense: Record Expense;
        ExpenseCurrency: Record Currency;
        ExpensePerDiem: Record "Expense Per Diem";
        CalculatedPerDiemAmount: Decimal;
        TotalReductionPercent: Decimal;
    begin
        Expense.Get(ExpenseNo);
        if Expense."Currency Code" = '' then
            ExpenseCurrency.InitRoundingPrecision()
        else
            ExpenseCurrency.Get(Expense."Currency Code");

        ExpensePerDiem.SetRange("Expense No.", ExpenseNo);
        ExpensePerDiem.FindFirst();

        CalculatedPerDiemAmount := ExpensePerDiem."Original Per Diem Amount";

        if (ExpensePerDiem.Breakfast) and (ExpensePerDiem."Breakfast Reduction Percent" <> 0) then
            TotalReductionPercent += ExpensePerDiem."Breakfast Reduction Percent";
        if (ExpensePerDiem.Lunch) and (ExpensePerDiem."Lunch Reduction Percent" <> 0) then
            TotalReductionPercent += ExpensePerDiem."Lunch Reduction Percent";
        if (ExpensePerDiem.Dinner) and (ExpensePerDiem."Dinner Reduction Percent" <> 0) then
            TotalReductionPercent += ExpensePerDiem."Dinner Reduction Percent";

        CalculatedPerDiemAmount := CalculatedPerDiemAmount - (ExpensePerDiem."Original Per Diem Amount" * TotalReductionPercent / 100);

        exit(Round(CalculatedPerDiemAmount, ExpenseCurrency."Amount Rounding Precision"));
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

    local procedure VerifyExpenseNotification(ExpenseNo: Code[20])
    var
        Expense: Record Expense;
    begin
        Expense.Get(ExpenseNo);

        Assert.ExpectedMessage(StrSubstNo(ExpenseAttachmentMissingMsg, Expense."No."), LibraryVariableStorage.DequeueText()); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty();
        Clear(Expense);
        LibraryNotificationMgt.RecallNotificationsForRecord(Expense);
    end;

    local procedure VerifyReceiptIsAttached(ExpenseNo: Code[20]; ExpectedAttached: Boolean; ReceiptId: Integer)
    var
        Expense: Record Expense;
    begin
        Expense.Get(ExpenseNo);

        Assert.AreEqual(
            ExpectedAttached,
            Expense."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Receipt Attached"), Format(ExpectedAttached), Expense.TableCaption()));
        Assert.AreEqual(
            ReceiptId,
            Expense."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Receipt Entry"), ReceiptId, Expense.TableCaption()));
    end;

    local procedure CreateExpenseWithRefundableAndNonRefundableItemization(
        var Expense: Record Expense;
        var ExpenseItemization: array[2] of Record "Expense Itemization";
        var ExpenseRuleHeader: Record "Expense Rule Header";
        var ExpenseRuleCondition: Record "Expense Rule Condition";
        Refundable: Boolean;
        CurrencyCode: Code[10];
        Amount: Decimal;
        RefundableAmount: Decimal;
        NonRefundableAmount: Decimal)
    var
        ExpenseSubCategory: array[2] of Record "Expense SubCategory";
    begin
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, '', '', CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", Refundable, Amount);

        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[1], Expense."Expense Category", true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[2], Expense."Expense Category", false);

        LibraryExpense.CreateExpenseItemization(ExpenseItemization[1], Expense, ExpenseSubCategory[1]."Expense Category Code", ExpenseSubCategory[1].Code, WorkDate(), RefundableAmount, LibraryRandom.RandInt(1));
        LibraryExpense.CreateExpenseItemization(ExpenseItemization[2], Expense, ExpenseSubCategory[2]."Expense Category Code", ExpenseSubCategory[2].Code, WorkDate(), NonRefundableAmount, LibraryRandom.RandInt(1));
    end;

    local procedure VerifyRefundableAmount(Expense: Record Expense; ExpectedRefundableAmount: Decimal; ExpectedRefundableAmountLCY: Decimal)
    begin
        Expense.Get(Expense."No.");

        Assert.AreEqual(
            ExpectedRefundableAmount,
            Expense."Refundable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Refundable Amount"), ExpectedRefundableAmount, Expense.TableCaption()));
        Assert.AreEqual(
            ExpectedRefundableAmountLCY,
            Expense."Refundable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Refundable Amount (LCY)"), ExpectedRefundableAmountLCY, Expense.TableCaption()));
    end;

    local procedure EnableSaaS(IsSaaS: Boolean)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaaS);
    end;

    local procedure CreateAndUpdateUserWithEmail(UserName: Code[50]; UserEmail: Text[80])
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst() then begin
            User."Authentication Email" := UserEmail;
            User.Modify();
        end else
            CreateUserWithEmail(UserName, UserEmail);
    end;

    local procedure CreateUserWithEmail(UserName: Code[50]; UserEmail: Text[80])
    var
        User: Record User;
    begin
        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := UserName;
        User."Authentication Email" := UserEmail;
        User.Insert(true);
    end;

    local procedure CreatePDFDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        DocumentAttachment.Init();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(PDFTestContentLbl);
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        NoSeriesList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExpenseApprovalSetupPageHandler(var ExpenseApprovalSetup: TestPage "Expense Approval Setup")
    begin
        ExpenseApprovalSetup."Approver No.".AssertEquals(LibraryVariableStorage.DequeueText());
        ExpenseApprovalSetup.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ExpectedConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [MessageHandler]
    procedure ExactMessageHandler(Msg: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Msg);
    end;

    [ModalPageHandler]
    procedure AddExpensesToExpenseReportModalPageHandler(var AddExpensesToExpenseReport: TestPage "Add Expenses To Expense Report")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            AddExpensesToExpenseReport.AddExpenseTo.SetValue(AddExpenseTo::"Existing Expense Report");
            AddExpensesToExpenseReport.ExpenseReportNo.SetValue(LibraryVariableStorage.DequeueText());
        end else
            AddExpensesToExpenseReport.AddExpenseTo.SetValue(AddExpenseTo::"New Expense Report");

        AddExpensesToExpenseReport.OK().Invoke();
    end;

    [PageHandler]
    procedure ExpenseReportPageHandler(var ExpenseReport: TestPage "Expense Report")
    begin
        LibraryVariableStorage.Enqueue(ExpenseReport."No.".Value);
        ExpenseReport.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SetDateInExpenseItemizationsModalPageHandler(var ExpenseItemizations: TestPage "Expense Itemizations")
    begin
        ExpenseItemizations."Expense Subcategory Code".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseItemizations."Start Date".SetValue(LibraryVariableStorage.DequeueDate());
        ExpenseItemizations.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VerifyAmountInExpenseItemizationsModalPageHandler(var ExpenseItemizationsPage: TestPage "Expense Itemizations")
    var
        ExpenseItemization: Record "Expense Itemization";
        Amount: Decimal;
    begin
        Amount := LibraryVariableStorage.DequeueDecimal();

        ExpenseItemizationsPage.Amount.AssertEquals(Amount);
        Assert.AreEqual(
            false,
            ExpenseItemizationsPage.Amount.Editable(),
            StrSubstNo(ValueMustBeEqualErr, ExpenseItemization.FieldCaption(Amount), Amount, ExpenseItemization.TableCaption()));
        ExpenseItemizationsPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VerifyQuantityInExpenseItemizationsModalPageHandler(var ExpenseItemizationsPage: TestPage "Expense Itemizations")
    begin
        ExpenseItemizationsPage.Quantity.AssertEquals(LibraryVariableStorage.DequeueInteger());
        ExpenseItemizationsPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PerDiemExpensesModalPageHandler(var ExpensePerDiem: TestPage "Per Diem Expenses")
    var
        ExpenseNo: Code[20];
    begin
        ExpenseNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);

        ExpensePerDiem.Breakfast.SetValue(LibraryVariableStorage.DequeueBoolean());
        ExpensePerDiem."Per Diem Amount".AssertEquals(CalculateAmountReduction(ExpenseNo));

        ExpensePerDiem.Lunch.SetValue(LibraryVariableStorage.DequeueBoolean());
        ExpensePerDiem."Per Diem Amount".AssertEquals(CalculateAmountReduction(ExpenseNo));

        ExpensePerDiem.Dinner.SetValue(LibraryVariableStorage.DequeueBoolean());
        ExpensePerDiem."Per Diem Amount".AssertEquals(CalculateAmountReduction(ExpenseNo));
        ExpensePerDiem.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PerDiemExpensesWithRuleModalPageHandler(var ExpensePerDiem: TestPage "Per Diem Expenses")
    begin
        Assert.AreEqual(
            false,
            ExpensePerDiem.Description.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePerDiem.Description.Caption(), ExpensePerDiem.Caption()));
        Assert.AreEqual(
            false,
            ExpensePerDiem.Date.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePerDiem.Date.Caption(), ExpensePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpensePerDiem.Breakfast.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpensePerDiem.Breakfast.Caption(), ExpensePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpensePerDiem.Lunch.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpensePerDiem.Lunch.Caption(), ExpensePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpensePerDiem.Dinner.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpensePerDiem.Dinner.Caption(), ExpensePerDiem.Caption()));
        Assert.AreEqual(
            false,
            ExpensePerDiem."Per Diem Amount".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePerDiem."Per Diem Amount".Caption(), ExpensePerDiem.Caption()));
        ExpensePerDiem.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PerDiemExpensesWithNoRuleModalPageHandler(var ExpensePerDiem: TestPage "Per Diem Expenses")
    begin
        Assert.AreEqual(
            false,
            ExpensePerDiem.Description.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePerDiem.Description.Caption(), ExpensePerDiem.Caption()));
        Assert.AreEqual(
            false,
            ExpensePerDiem.Date.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePerDiem.Date.Caption(), ExpensePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpensePerDiem.Breakfast.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpensePerDiem.Breakfast.Caption(), ExpensePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpensePerDiem.Lunch.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpensePerDiem.Lunch.Caption(), ExpensePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpensePerDiem.Dinner.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpensePerDiem.Dinner.Caption(), ExpensePerDiem.Caption()));
        Assert.AreEqual(
            false,
            ExpensePerDiem."Per Diem Amount".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpensePerDiem."Per Diem Amount".Caption(), ExpensePerDiem.Caption()));
        ExpensePerDiem.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewPerDiemExpensesWithRuleModalPageErrorHandler(var ExpensePerDiem: TestPage "Per Diem Expenses")
    begin
        asserterror ExpensePerDiem.New();

        Assert.ExpectedError(CannotInsertPerDiemInfoErr);
        ExpensePerDiem.Ok().Invoke();
    end;

    [ModalPageHandler]
    procedure NewPerDiemExpensesWithNoRuleModalPageErrorHandler(var ExpensePerDiem: TestPage "Per Diem Expenses")
    begin
        asserterror ExpensePerDiem.New();

        Assert.ExpectedError(CannotInsertPerDiemInfoErr);
        ExpensePerDiem.Ok().Invoke();
    end;

    [ModalPageHandler]
    procedure CreateExpenseItemizationsWithSubCategoryHandler(var ExpenseItemizationsPage: TestPage "Expense Itemizations")
    begin
        ExpenseItemizationsPage."Expense Subcategory Code".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseItemizationsPage.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        ExpenseItemizationsPage."Daily Rate".SetValue(LibraryVariableStorage.DequeueDecimal());

        ExpenseItemizationsPage.New();
        ExpenseItemizationsPage."Expense Subcategory Code".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseItemizationsPage.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        ExpenseItemizationsPage."Daily Rate".SetValue(LibraryVariableStorage.DequeueDecimal());
        ExpenseItemizationsPage.OK().Invoke();
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