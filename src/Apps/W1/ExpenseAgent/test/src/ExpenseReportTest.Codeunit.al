// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 148306 "Expense Report Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryJob: Codeunit "Library - Job";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IsInitialized: Boolean;
        AddExpenseTo: Option "New Expense Report","Existing Expense Report";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        CannotAssignManuallyErr: Label 'You may not enter numbers manually. If you want to enter numbers manually, please activate %1 in %2 %3.', Comment = '%1 = Manual Nos. setting, %2 = No. Series table caption, %3 = No. Series Code';
        ExpenseReportLineDoesNotExistErr: Label 'There is no expense report lines with the number %1.', Comment = '%1 - Document No.';
        CannotReleaseDocumentWithNothingToRefundErr: Label 'Cannot release the Expense Report No. %1 because there is nothing to refund for this Line No. %2.', Comment = '%1 - Expense No. , %2 - Line No.';
        FieldShouldNotBeEditableErr: Label '%1 should not be editable in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        FieldShouldBeEditableErr: Label '%1 should be editable in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        FieldShouldBeVisibleErr: Label '%1 should be visible in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        FieldShouldNotBeVisibleErr: Label '%1 should not be visible in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        ItemizationTotalMismatchErr: Label 'Itemization total %1 must be equal to expense amount %2.', Comment = '%1 = Itemization total amount, %2 = Expense amount';
        PageMustBeEditableErr: Label '%1 page must be editable.', Comment = '%1 = Page Caption';
        NonRefundableAmountCannotBeNegativeErr: Label '%1 cannot be in negative on Expense Report No. %2, Line No. %3.', Comment = '%1 = Non-Refundable Amount, %2 = Expense Report No., %3 = Line No.';
        ExpenseUserMustBeLinkedToAnEmployeeErr: Label 'Expense User %1 must be linked to an Employee No.', Comment = '%1 = Expense User No.';
        CannotInsertPerDiemInfoErr: Label 'New method failed because Insert is not allowed.';
        NoLbl: Label 'No_';
        ExpenseReportNoLbl: Label 'ExpenseReportNo';
        CompanyAddress1Lbl: Label 'CompanyAddress1';
        CompanyAddress2Lbl: Label 'CompanyAddress2';
        CompanyAddress3Lbl: Label 'CompanyAddress3';
        CompanyAddress4Lbl: Label 'CompanyAddress4';
        CompanyAddress5Lbl: Label 'CompanyAddress5';
        CompanyAddress6Lbl: Label 'CompanyAddress6';
        CompanyAddress7Lbl: Label 'CompanyAddress7';
        CompanyAddress8Lbl: Label 'CompanyAddress8';
        CompanyCityLbl: Label 'CompanyCity';
        ReportMonthLbl: Label 'ReportMonth';
        HeaderDescriptionLbl: Label 'HeaderDescription';
        JobTitleLbl: Label 'JobTitle';
        MileageStartingPointLbl: Label 'Mileage_StartingPoint';
        DocumentNoMileageLineLbl: Label 'Document_No_MileageLine';
        MileageLineNoLbl: Label 'Mileage_LineNo';
        MileageEndingPointLbl: Label 'Mileage_EndingPoint';
        MileageMileageLbl: Label 'Mileage_Mileage';
        MileageUOMLbl: Label 'Mileage_UOM';
        MileageAmountPerMileageLbl: Label 'Mileage_AmountPerMileage';
        MileageAmountLCYLbl: Label 'Mileage_AmountLCY';
        PerDiemExpenseLocationLbl: Label 'PerDiem_ExpenseLocation';
        PerDiemLineNoLbl: Label 'PerDiem_LineNo';
        PerDiemCurrencyLbl: Label 'PerDiem_Currency';
        DocumentNoPerDiemLineLbl: Label 'Document_No_PerDiemLine';
        PerDiemAmountLbl: Label 'PerDiem_Amount';
        PerDiemUnitAmountLbl: Label 'PerDiem_UnitAmount';
        OtherCategoryLbl: Label 'Other_Category';
        OtherLineNoLbl: Label 'Other_LineNo';
        OtherRefundableAmountLCYLbl: Label 'Other_RefundableAmountLCY';
        DocumentNoOtherExpenseLineLbl: Label 'Document_No_OtherExpenseLine';
        ExpenseUserNoLbl: Label 'ExpenseUserNo';
        ExpenseUserNameLbl: Label 'ExpenseUserName';
        StatusLbl: Label 'Status';
        ExpenseCategoryLbl: Label 'Expense_Category';
        MerchantLbl: Label 'Merchant';
        PaymentMethodLbl: Label 'Payment_Method';
        AmountLbl: Label 'Amount';
        CurrencyLbl: Label 'Currency_Code';
        AmountLCYLbl: Label 'Amount_LCY';
        ReimbursableAmountLCYLbl: Label 'Reimbursable_Amount_LCY';
        ProjectNoLbl: Label 'Project_No_';
        BillableLbl: Label 'Billable';
        CoverReportTitleLbl: Label 'ReportTitleLbl';
        CoverCompanyAddress1Lbl: Label 'CompanyAddress1';
        CoverCompanyAddress2Lbl: Label 'CompanyAddress2';
        CoverCompanyAddress3Lbl: Label 'CompanyAddress3';
        CoverCompanyAddress4Lbl: Label 'CompanyAddress4';
        CoverCompanyAddress5Lbl: Label 'CompanyAddress5';
        CoverCompanyAddress6Lbl: Label 'CompanyAddress6';
        CoverCompanyAddress7Lbl: Label 'CompanyAddress7';
        CoverCompanyAddress8Lbl: Label 'CompanyAddress8';
        CoverExpenseReportNoLbl: Label 'ExpenseReportNo';
        CoverExpenseUserNameLbl: Label 'ExpenseUserName';
        CoverExpenseReportDateLbl: Label 'ExpenseReportDate';
        CoverPostingDateLbl: Label 'PostingDate';
        CoverDescriptionLbl: Label 'Description';
        CoverAntiCorruptionAttestationLbl: Label 'AntiCorruptionAttestation';
        CoverAntiCorruptionDescriptionLbl: Label 'AntiCorruptionDescription';
        CoverTotalAmountLCYLbl: Label 'TotalAmountLCY';
        CoverTotalReimbursableAmountLCYLbl: Label 'TotalReimbursableAmountLCY';
        CoverTotalPaidByCompanyLCYLbl: Label 'TotalPaidByCompanyLCY';
        CoverTotalNonRefundableAmountLCYLbl: Label 'TotalNonRefundableAmountLCY';
        CoverTotalRefundableAmountLCYLbl: Label 'TotalRefundableAmountLCY';
        CoverCurrencyCodeLbl: Label 'CurrencyCode';
        CoverSubmittedByLbl: Label 'SubmittedBy';
        CoverApprovedByLbl: Label 'ApprovedBy';
        ExpenseReportTitleLbl: Label 'Expense Report';
        ExpenseReportLocationMissingMsg: Label '%1 is missing in Expense Report No. %2, Line No. %3.', Comment = '%1 = Expense Location Caption, %2 = Expense Report No., %3 = Line No.';

    [Test]
    procedure ExpenseReportNosIsRequiredWhenCreatingExpenseReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 580546] Verify that the "Expense Reports Nos." is required When creating Expense Report.
        Initialize();

        // [GIVEN] Update "Expense Reports Nos." in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Expense Reports Nos.", '');
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Create Expense Report.
        asserterror LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [THEN] Verify that system must throw an error When "Expense Reports Nos." is empty in Expense Agent Setup.
        Assert.ExpectedTestFieldError(ExpenseAgentSetup.FieldCaption("Expense Reports Nos."), '');
    end;

    [Test]
    procedure ExpenseReportCanBeCreatedWhenNumberSeriesExists()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 580546] Verify that the Expense Report can be created When Number Series exists.
        Initialize();

        // [GIVEN] Setup Number Series in Expense Management.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [THEN] Verify that the Expense Report "No." is assigned.
        ExpenseReportHeader.TestField("No.");
    end;

    [Test]
    procedure NoCannotBeUpdatedInExpenseReportManuallyIfManualNosIsFalse()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        NoSeries: Record "No. Series";
        ManualNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that the "No." field cannot be updated in Expense Report if "Manual Nos." is set to false in "No. Series".
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Get "No. Series" and ensure "Manual Nos." is false.
        NoSeries.Get(ExpenseReportHeader."No. Series");
        NoSeries.Validate("Manual Nos.", false);
        NoSeries.Modify();

        // [GIVEN] Generate Manual No.
        ManualNo := LibraryUtility.GenerateRandomCode(ExpenseReportHeader.FieldNo("No."), Database::"Expense Report Header");

        // [WHEN] Update "No." in Expense Report.
        asserterror ExpenseReportHeader.Validate("No.", ManualNo);

        // [THEN] Verify that system must throw an error When "No." is updated manually.
        Assert.ExpectedError(StrSubstNo(CannotAssignManuallyErr, NoSeries.FieldCaption("Manual Nos."), NoSeries.TableCaption(), NoSeries.Code));
    end;

    [Test]
    procedure NoBeUpdatedInExpenseReportManuallyIfManualNosIsTrue()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        NoSeries: Record "No. Series";
        ManualNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that the "No." field can be updated in Expense Report if "Manual Nos." is set to true in "No. Series".
        Initialize();

        // [GIVEN] Remove "Expense Reports Nos." from Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Expense Reports Nos.", '');
        ExpenseAgentSetup.Modify();

        // [GIVEN] Setup Number Series in Expense Management.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Get "No. Series" and Update "Manual Nos." to true.
        NoSeries.Get(ExpenseReportHeader."No. Series");
        NoSeries.Validate("Manual Nos.", true);
        NoSeries.Modify();

        // [GIVEN] Generate Manual No.
        ManualNo := LibraryUtility.GenerateRandomCode(ExpenseReportHeader.FieldNo("No."), Database::"Expense Report Header");

        // [WHEN] Update "No." in Expense Report.
        ExpenseReportHeader.Validate("No.", ManualNo);

        // [THEN] Verify that the "No." field is updated and "No. Series" is blank.
        Assert.AreEqual(
            ManualNo,
            ExpenseReportHeader."No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("No."), ManualNo, ExpenseReportHeader.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseReportHeader."No. Series",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("No. Series"), '', ExpenseReportHeader.TableCaption()));
    end;

    [Test]
    procedure NoSeriesCannotBeChangedWhenSameNoIsUpdatedAgainInExpenseReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        NoSeries: Record "No. Series";
    begin
        // [SCENARIO 580546] Verify that the "No. Series" cannot be changed When same "No." is updated again in Expense Report.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Get "No. Series".
        NoSeries.Get(ExpenseReportHeader."No. Series");

        // [WHEN] Update "No." with same value.
        ExpenseReportHeader.Validate("No.", ExpenseReportHeader."No.");

        // [THEN] Verify that the "No. Series" is not changed.
        Assert.AreEqual(
            NoSeries.Code,
            ExpenseReportHeader."No. Series",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("No. Series"), NoSeries.Code, ExpenseReportHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure CurrencyCodeCannotBeChangedAfterExpenseReportIsReleased()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        Currency: Record Currency;
        Expense: Record Expense;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Currency Code" cannot be changed When Expense Report is released.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, Currency.Code, LibraryRandom.RandInt(50));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Update "Currency Code" in Expense Report.
        asserterror ExpenseReportHeader.Validate("Reimbursement Currency Code", '');

        // [THEN] Verify that the "Currency Code" cannot be changed.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure FieldsCanBeChangedBeforeReleaseButLockedAfter()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        Currency: Record Currency;
        Expense: Record Expense;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpReport: Codeunit "Create Expense Report";
        CurrencyCode: Code[10];
        InitialDesc: Text[100];
        NewDesc: Text[100];
    begin
        // [SCENARIO 580546] Verify that some fields can be changed Before release but cannot be changed After Expense Report is released.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, Currency.Code, LibraryRandom.RandInt(50));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", Currency.Code, Expense."VAT Bus. Posting Group");
        InitialDesc := ExpenseReportHeader.Description;

        // [GIVEN] Update "Description" and "Currency Code" in Expense Report.
        NewDesc := LibraryUtility.GenerateRandomCode(ExpenseReportHeader.FieldNo(Description), Database::"Expense Report Header");
        ExpenseReportHeader.Validate(Description, NewDesc);
        ExpenseReportHeader.Modify();

        // [WHEN] Insert Expense Line.
        CreateExpReport.AddExpensesToReport(ExpenseReportHeader);

        // [THEN] Verify that the fields are updated.
        Assert.AreEqual(
            NewDesc,
            ExpenseReportHeader.Description,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption(Description), NewDesc, ExpenseReportHeader.TableCaption()));
        Assert.AreEqual(
            Currency.Code,
            ExpenseReportHeader."Reimbursement Currency Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Reimbursement Currency Code"), Currency.Code, ExpenseReportHeader.TableCaption()));

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Update "Description" after release.
        asserterror ExpenseReportHeader.Validate(Description, InitialDesc);

        // [THEN] Verify that the "Description" cannot be changed after release.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure FieldsCannotBeChangedWhenExpenseReportIsReleased()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        Currency: Record Currency;
        Expense: Record Expense;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpReport: Codeunit "Create Expense Report";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that some fields cannot be changed When Expense Report is released.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, Currency.Code, LibraryRandom.RandInt(50));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", Currency.Code, Expense."VAT Bus. Posting Group");
        ExpenseReportHeader.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseReportHeader.FieldNo(Description), Database::"Expense Report Header"));
        ExpenseReportHeader.Modify();

        // [GIVEN] Insert Expense Line.
        CreateExpReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();
        Commit();

        // [WHEN] Update "Expense User No." in Expense Report.
        asserterror ExpenseReportHeader.Validate("Expense User No.", '');

        // [THEN] Verify that the "Expense User No." cannot be changed.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));

        // [WHEN] Update "Currency Code" in Expense Report.
        asserterror ExpenseReportHeader.Validate("Reimbursement Currency Code", '');

        // [THEN] Verify that the "Currency Code" cannot be changed.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));

        // [WHEN] Update "Description" in Expense Report.
        asserterror ExpenseReportHeader.Validate(Description, '');

        // [THEN] Verify that the "Description" cannot be changed.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));

        // [WHEN] Update "Shortcut Dimension 1 Code" in Expense Report.
        asserterror ExpenseReportHeader.Validate("Shortcut Dimension 1 Code", '');

        // [THEN] Verify that the "Shortcut Dimension 1 Code" cannot be changed.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));

        // [WHEN] Update "Shortcut Dimension 2 Code" in Expense Report.
        asserterror ExpenseReportHeader.Validate("Shortcut Dimension 2 Code", '');

        // [THEN] Verify that the "Shortcut Dimension 2 Code" cannot be changed.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));

        // [GIVEN] Get Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [WHEN] Update "Job No." in Expense Report Line.
        asserterror ExpenseReportLine.Validate("Job No.", '');

        // [THEN] Verify that the "Job No." cannot be changed in Expense Report Line.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));

        // [WHEN] Update "Job Task No." in Expense Report Line.
        asserterror ExpenseReportLine.Validate("Job Task No.", '');

        // [THEN] Verify that the "Job Task No." cannot be changed in Expense Report Line.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));
    end;

    [Test]
    procedure DimensionSetUpdatedWhenShortcutDimsChangedOnReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExpectedDimSetID: Integer;
    begin
        // [SCENARIO 580546] Verify that the "Dimension Set ID" must be updated When Shortcut Dimensions are updated in Expense Report.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Global Dimension Value 1 and 2.
        LibraryDimension.GetGlobalDimCodeValue(1, DimValue1);
        LibraryDimension.GetGlobalDimCodeValue(2, DimValue2);

        // [GIVEN] Update General Ledger Setup with Shortcut Dimensions.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Shortcut Dimension 1 Code" := DimValue1."Dimension Code";
        GeneralLedgerSetup."Shortcut Dimension 2 Code" := DimValue2."Dimension Code";
        GeneralLedgerSetup.Modify();

        // [GIVEN] Get Expected Dimension Set ID after adding Dimension Value 1 and 2.
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimValue1);
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimValue2);

        // [WHEN] Update Shortcut Dimensions 1 and 2 in Expense Report.
        ExpenseReportHeader.Validate("Shortcut Dimension 1 Code", DimValue1.Code);
        ExpenseReportHeader.Validate("Shortcut Dimension 2 Code", DimValue2.Code);
        ExpenseReportHeader.Modify();

        // [THEN] Verify that the "Dimension Set ID" is updated.
        Assert.AreEqual(
            ExpectedDimSetID,
            ExpenseReportHeader."Dimension Set ID",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Dimension Set ID"), ExpectedDimSetID, ExpenseReportHeader.TableCaption()));
        Assert.AreEqual(
            DimValue1.Code,
            ExpenseReportHeader."Shortcut Dimension 1 Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Shortcut Dimension 1 Code"), DimValue1.Code, ExpenseReportHeader.TableCaption()));
        Assert.AreEqual(
            DimValue2.Code,
            ExpenseReportHeader."Shortcut Dimension 2 Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Shortcut Dimension 2 Code"), DimValue2.Code, ExpenseReportHeader.TableCaption()));
    end;

    [Test]
    procedure ShortcutDimensionsMustBeUpdatedWhenDimensionSetIDIsUpdatedInExpenseReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        ExpectedDimSetID: Integer;
    begin
        // [SCENARIO 580546] Verify that the Shortcut Dimensions must be updated When "Dimension Set ID" is updated in Expense Report.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Global Dimension Value 1 and 2.
        LibraryDimension.GetGlobalDimCodeValue(1, DimValue1);
        LibraryDimension.GetGlobalDimCodeValue(2, DimValue2);

        // [GIVEN] Get Expected Dimension Set ID after adding Dimension Value 1 and 2.
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimValue1);
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimValue2);

        // [WHEN] Update "Dimension Set ID" in Expense Report.
        ExpenseReportHeader.Validate("Dimension Set ID", ExpectedDimSetID);

        // [THEN] Verify that the "Dimension Set ID" and Shortcut Dimensions are updated.
        Assert.AreEqual(
            ExpectedDimSetID,
            ExpenseReportHeader."Dimension Set ID",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Dimension Set ID"), ExpectedDimSetID, ExpenseReportHeader.TableCaption()));
        Assert.AreEqual(
            DimValue1.Code,
            ExpenseReportHeader."Shortcut Dimension 1 Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Shortcut Dimension 1 Code"), DimValue1.Code, ExpenseReportHeader.TableCaption()));
        Assert.AreEqual(
            DimValue2.Code,
            ExpenseReportHeader."Shortcut Dimension 2 Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Shortcut Dimension 2 Code"), DimValue2.Code, ExpenseReportHeader.TableCaption()));
    end;

    [Test]
    procedure ExpenseUserNoCanBeChangedBeforeRelease()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: array[2] of Record "Expense User";
    begin
        // [SCENARIO 580546] Verify that the "Expense User No." can be changed before the Expense Report is released.
        Initialize();

        // [GIVEN] Create two Expense Users.
        LibraryExpense.CreateExpenseUser(ExpenseUser[1]);
        LibraryExpense.CreateExpenseUser(ExpenseUser[2]);

        // [WHEN] Create Expense Report for first Employee.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser[1]."No.", '', '');

        // [GIVEN] Change "Expense User No." to second Employee before release.
        ExpenseReportHeader.Validate("Expense User No.", ExpenseUser[2]."No.");
        ExpenseReportHeader.Modify();

        // [THEN] Verify that "Expense User No." is updated.
        Assert.AreEqual(
            ExpenseUser[2]."No.",
            ExpenseReportHeader."Expense User No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Expense User No."), ExpenseUser[2]."No.", ExpenseReportHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure CurrencyCodeIsUpdatedInLinesBeforeRelease()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        Currency1: Record Currency;
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CurrencyCode1: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Currency Code" is updated in Expense Report Lines When changed on Expense Report before release.
        Initialize();

        // [GIVEN] Create currency with exchange rates.
        CurrencyCode1 := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        Currency1.Get(CurrencyCode1);

        // [GIVEN] Create Expense with Currency.
        CreateExpense(Expense, true, Currency1.Code, LibraryRandom.RandInt(50));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [WHEN] Create Expense Report with Currency.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [THEN] Verify line Currency Code matches header Currency Code.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        Assert.AreEqual(
            ExpenseReportHeader."Reimbursement Currency Code",
            ExpenseReportLine."Expense Currency Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Currency Code"), ExpenseReportHeader."Reimbursement Currency Code", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ShortcutDimensionsAreUpdatedInLinesBeforeRelease()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        Expense: Record Expense;
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO 580546] Verify that updating Shortcut Dimensions on Expense Report updates them in Expense Report Lines before release.
        Initialize();

        // [GIVEN] Create and release an Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(50));
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Get Global Dimension Values.
        LibraryDimension.GetGlobalDimCodeValue(1, DimValue1);
        LibraryDimension.GetGlobalDimCodeValue(2, DimValue2);

        // [WHEN] Update Shortcut Dimensions on header before release.
        ExpenseReportHeader.Validate("Shortcut Dimension 1 Code", DimValue1.Code);
        ExpenseReportHeader.Validate("Shortcut Dimension 2 Code", DimValue2.Code);
        ExpenseReportHeader.Modify();

        // [THEN] Verify line dimensions match header dimensions.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        Assert.AreEqual(
            ExpenseReportHeader."Shortcut Dimension 1 Code",
            ExpenseReportLine."Shortcut Dimension 1 Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Shortcut Dimension 1 Code"), ExpenseReportHeader."Shortcut Dimension 1 Code", ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ExpenseReportHeader."Shortcut Dimension 2 Code",
            ExpenseReportLine."Shortcut Dimension 2 Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Shortcut Dimension 2 Code"), ExpenseReportHeader."Shortcut Dimension 2 Code", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostingDateCanBeChangedAfterReopen()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        Expense: Record Expense;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        NewPostingDate: Date;
    begin
        // [SCENARIO 580546] Verify that "Posting Date" can be changed after the Expense Report is reopened.
        Initialize();

        // [GIVEN] Find Post Code and Create & Release Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(50));
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Attempt to change Posting Date while released.
        asserterror ExpenseReportHeader.Validate("Posting Date", CalcDate('<+1D>', ExpenseReportHeader."Posting Date"));

        // [THEN] Verify that the "Posting Date" cannot be changed when Expense Report is released.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption("Status"), Format(ExpenseReportHeader.Status::Open));

        // [GIVEN] Reopen Expense Report.
        ExpenseReportHeader.SetFilter("No.", ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualReopen(ExpenseReportHeader);

        // [WHEN] Change Posting Date.
        NewPostingDate := CalcDate('<+1D>', WorkDate());
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.Validate("Posting Date", NewPostingDate);
        ExpenseReportHeader.Modify();

        // [THEN] Verify that the "Posting Date" is updated.
        Assert.AreEqual(
            NewPostingDate,
            ExpenseReportHeader."Posting Date",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Posting Date"), Format(NewPostingDate), ExpenseReportHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportLinesAreDeletedWhenReportIsDeleted()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        Expense: Record Expense;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO 580546] Verify that Expense Report Lines are deleted When Expense Report is deleted.
        Initialize();

        // [GIVEN] Find Post Code and Create & Release Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(50));
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Confirm the line exists.
        ExpenseReportLine.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseReportLine, 1);

        // [WHEN] Delete Expense Report.
        ExpenseReportHeader.Delete(true);

        // [THEN] Verify the Expense Report Lines was deleted.
        ExpenseReportLine.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseReportLine, 0);
    end;

    [Test]
    procedure RelinkExpenseReportLineMustUpdateExpenseReportNoOnExpense()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO] Verify relinking Expense Report Line updates Expense."Expense Report No.".
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory,
            ExpenseCategory."Reimbursement Type"::"Employee Paid",
            ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target expense reports for same expense user.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Add expense to source report to create the source line.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");

        // [WHEN] Move line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        // [THEN] Verify Expense."Expense Report No." is updated to target report.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            TargetExpenseReportHeader."No.",
            Expense."Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Report No."), TargetExpenseReportHeader."No.", Expense.TableCaption()));

        // [THEN] Verify source line no longer exists for the expense.
        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", SourceExpenseReportHeader."No.");
        Assert.AreEqual(
            false,
            ExpenseReportLine.FindFirst(),
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Document No."), SourceExpenseReportHeader."No.", ExpenseReportLine.TableCaption()));

        // [THEN] Verify target line exists for the expense.
        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", TargetExpenseReportHeader."No.");
        Assert.AreEqual(
            true,
            ExpenseReportLine.FindFirst(),
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Document No."), TargetExpenseReportHeader."No.", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure RelinkExpenseReportLineMustResetPolicyEvaluation()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        CreateExpReport: Codeunit "Create Expense Report";
        SourceSystemId: Guid;
    begin
        // [SCENARIO] Moving an evaluated line resets policy state because the new line has a new identity.
        Initialize();

        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory,
            ExpenseCategory."Reimbursement Type"::"Employee Paid",
            ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");

        LibraryExpense.CreateExpensePolicy(ExpensePolicy, ExpenseCategory.Code, 'Policy text.');
        LibraryExpense.CreateExpensePolicyEvaluation(
            ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Policy violation.', false);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        Assert.AreEqual("Expense Policy Status"::Flagged, ExpenseReportLine.GetPolicyStatus(), 'Precondition: the source line must be flagged.');
        SourceSystemId := ExpenseReportLine.SystemId;

        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        Assert.AreNotEqual(SourceSystemId, ExpenseReportLine.SystemId, 'The moved line must have a new SystemId.');
        Assert.AreEqual(0DT, ExpenseReportLine."Policies Evaluated At", 'The moved line must not retain the source evaluation timestamp.');
        Assert.AreEqual(0, ExpenseReportLine."Policy Eval Version", 'The moved line must restart policy versioning.');
        Assert.AreEqual(0, ExpenseReportLine."Evaluated Policy Version", 'The moved line must not retain the evaluated source version.');
        Assert.AreEqual("Expense Policy Status"::"Not Evaluated", ExpenseReportLine.GetPolicyStatus(), 'The moved line must require policy evaluation.');

        ExpensePolicyEvaluation.SetRange("Subject System Id", SourceSystemId);
        Assert.RecordIsEmpty(ExpensePolicyEvaluation);
    end;

    [Test]
    procedure RelinkExpenseReportLineMustMoveAssociatedRecordsAndRetriggerRuleViolation()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        DocumentAttachment: Record "Document Attachment";
        CreateExpReport: Codeunit "Create Expense Report";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
        SourceLineNo: Integer;
        TargetLineNo: Integer;
    begin
        // [SCENARIO] Verify relinking moves itemization/participant/per diem/attachment and re-triggers rule violations.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");
        SourceLineNo := ExpenseReportLine."Line No.";

        // [GIVEN] Add associated records on source line.
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, WorkDate(), 10, 1);
        CreateExpenseReportLineParticipant(ExpenseReportLineParticip, ExpenseReportLine);
        LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, '', WorkDate(), false, false, false, 10);
        CreateDocumentAttachmentForExpenseReportLine(DocumentAttachment, ExpenseReportLine, 'RelinkMove.txt');

        // [GIVEN] Create rule that requires justification and trigger rule validation on source line.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader,
            ExpenseRuleCondition,
            ExpenseCategory.Code,
            '',
            WorkDate(),
            ExpenseRuleHeader."Justification Required"::Always,
            '',
            '',
            ExpenseRuleCondition."Condition Type"::"Max Amount",
            99999);
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [WHEN] Relink line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        TargetLineNo := ExpenseReportLine."Line No.";

        // [THEN] Verify source associated records are removed.
        ExpenseReportLineItem.SetRange("Expense Report No.", SourceExpenseReportHeader."No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", SourceLineNo);
        Assert.AreEqual(false, ExpenseReportLineItem.FindFirst(), StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineItem.FieldCaption("Expense Report No."), SourceExpenseReportHeader."No.", ExpenseReportLineItem.TableCaption()));

        ExpenseReportLineParticip.SetRange("Expense Report No.", SourceExpenseReportHeader."No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", SourceLineNo);
        Assert.AreEqual(false, ExpenseReportLineParticip.FindFirst(), StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticip.FieldCaption("Expense Report No."), SourceExpenseReportHeader."No.", ExpenseReportLineParticip.TableCaption()));

        ExpenseReportLinePerDiem.SetRange("Expense Report No.", SourceExpenseReportHeader."No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", SourceLineNo);
        Assert.AreEqual(false, ExpenseReportLinePerDiem.FindFirst(), StrSubstNo(ValueMustBeEqualErr, ExpenseReportLinePerDiem.FieldCaption("Expense Report No."), SourceExpenseReportHeader."No.", ExpenseReportLinePerDiem.TableCaption()));

        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        DocumentAttachment.SetRange("No.", SourceExpenseReportHeader."No.");
        DocumentAttachment.SetRange("Line No.", SourceLineNo);
        Assert.AreEqual(false, DocumentAttachment.FindFirst(), StrSubstNo(ValueMustBeEqualErr, DocumentAttachment.FieldCaption("No."), SourceExpenseReportHeader."No.", DocumentAttachment.TableCaption()));

        ExpenseReportRuleViolation.SetRange("Expense Report No.", SourceExpenseReportHeader."No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", SourceLineNo);
        Assert.AreEqual(false, ExpenseReportRuleViolation.FindFirst(), StrSubstNo(ValueMustBeEqualErr, ExpenseReportRuleViolation.FieldCaption("Expense Report No."), SourceExpenseReportHeader."No.", ExpenseReportRuleViolation.TableCaption()));

        // [THEN] Verify target associated records exist.
        ExpenseReportLineItem.SetRange("Expense Report No.", TargetExpenseReportHeader."No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", TargetLineNo);
        Assert.AreEqual(true, ExpenseReportLineItem.FindFirst(), StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineItem.FieldCaption("Expense Report No."), TargetExpenseReportHeader."No.", ExpenseReportLineItem.TableCaption()));

        ExpenseReportLineParticip.SetRange("Expense Report No.", TargetExpenseReportHeader."No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", TargetLineNo);
        Assert.AreEqual(true, ExpenseReportLineParticip.FindFirst(), StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticip.FieldCaption("Expense Report No."), TargetExpenseReportHeader."No.", ExpenseReportLineParticip.TableCaption()));

        ExpenseReportLinePerDiem.SetRange("Expense Report No.", TargetExpenseReportHeader."No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", TargetLineNo);
        Assert.AreEqual(true, ExpenseReportLinePerDiem.FindFirst(), StrSubstNo(ValueMustBeEqualErr, ExpenseReportLinePerDiem.FieldCaption("Expense Report No."), TargetExpenseReportHeader."No.", ExpenseReportLinePerDiem.TableCaption()));

        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        DocumentAttachment.SetRange("No.", TargetExpenseReportHeader."No.");
        DocumentAttachment.SetRange("Line No.", TargetLineNo);
        Assert.AreEqual(true, DocumentAttachment.FindFirst(), StrSubstNo(ValueMustBeEqualErr, DocumentAttachment.FieldCaption("No."), TargetExpenseReportHeader."No.", DocumentAttachment.TableCaption()));

        ExpenseReportRuleViolation.SetRange("Expense Report No.", TargetExpenseReportHeader."No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", TargetLineNo);
        Assert.AreEqual(true, ExpenseReportRuleViolation.FindFirst(), StrSubstNo(ValueMustBeEqualErr, ExpenseReportRuleViolation.FieldCaption("Expense Report No."), TargetExpenseReportHeader."No.", ExpenseReportRuleViolation.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportLineItemizationDeletedWhenExpenseCategoryChangedAndConfirmed()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO 639727] Itemization on an Expense Report Line is deleted when the Expense Category is changed and the user confirms.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category with Reimbursement Type "Employee Paid".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);

        // [GIVEN] Release the Expense.
        Expense.PerformManualRelease();

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Add the Expense to the Expense Report.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [GIVEN] Find the Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");

        // [GIVEN] Set the line's required detail to Itemize so the associated Itemization is detected when the category changes.
        ExpenseReportLine."Expense Detail Required" := ExpenseReportLine."Expense Detail Required"::Itemize;
        ExpenseReportLine.Modify();

        // [GIVEN] Create Expense Report Line Itemization.
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, WorkDate(), 10, 1);

        // [WHEN] Update "Expense Category" in Expense Report Line and confirm the deletion of associated records.
        ExpenseReportLine.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is cleared in the Expense Report Line.
        Assert.AreEqual('', ExpenseReportLine."Expense Category", StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Category"), '', ExpenseReportLine.TableCaption()));

        // [THEN] Verify that the associated Itemization is deleted.
        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportLineItem, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure ExpenseReportLineItemizationKeptWhenExpenseCategoryChangedAndNotConfirmed()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO 639727] Itemization on an Expense Report Line is kept when the Expense Category change is not confirmed.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category with Reimbursement Type "Employee Paid".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);

        // [GIVEN] Release the Expense.
        Expense.PerformManualRelease();

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Add the Expense to the Expense Report.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [GIVEN] Find the Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");

        // [GIVEN] Set the line's required detail to Itemize so the associated Itemization is detected when the category changes.
        ExpenseReportLine."Expense Detail Required" := ExpenseReportLine."Expense Detail Required"::Itemize;
        ExpenseReportLine.Modify();

        // [GIVEN] Create Expense Report Line Itemization.
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, WorkDate(), 10, 1);

        // [GIVEN] Save the setup so the declined change can be rolled back.
        Commit();

        // [WHEN] Update "Expense Category" in Expense Report Line and decline the deletion of associated records.
        asserterror ExpenseReportLine.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is not changed in the Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseCategory.Code, ExpenseReportLine."Expense Category", StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Category"), ExpenseCategory.Code, ExpenseReportLine.TableCaption()));

        // [THEN] Verify that the associated Itemization is kept.
        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportLineItem, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportLineParticipantDeletedWhenExpenseCategoryChangedAndConfirmed()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO 639727] Participants on an Expense Report Line are deleted when the Expense Category is changed and the user confirms.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category with Reimbursement Type "Employee Paid".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);

        // [GIVEN] Release the Expense.
        Expense.PerformManualRelease();

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Add the Expense to the Expense Report.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [GIVEN] Find the Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");

        // [GIVEN] Set the line's required detail to Participants so the associated Participant is detected when the category changes.
        ExpenseReportLine."Expense Detail Required" := ExpenseReportLine."Expense Detail Required"::Participants;
        ExpenseReportLine.Modify();

        // [GIVEN] Create Expense Report Line Participant.
        CreateExpenseReportLineParticipant(ExpenseReportLineParticip, ExpenseReportLine);

        // [WHEN] Update "Expense Category" in Expense Report Line and confirm the deletion of associated records.
        ExpenseReportLine.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is cleared in the Expense Report Line.
        Assert.AreEqual('', ExpenseReportLine."Expense Category", StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Category"), '', ExpenseReportLine.TableCaption()));

        // [THEN] Verify that the associated Participant is deleted.
        ExpenseReportLineParticip.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportLineParticip, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure ExpenseReportLineParticipantKeptWhenExpenseCategoryChangedAndNotConfirmed()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO 639727] Participants on an Expense Report Line are kept when the Expense Category change is not confirmed.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category with Reimbursement Type "Employee Paid".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);

        // [GIVEN] Release the Expense.
        Expense.PerformManualRelease();

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Add the Expense to the Expense Report.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [GIVEN] Find the Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");

        // [GIVEN] Set the line's required detail to Participants so the associated Participant is detected when the category changes.
        ExpenseReportLine."Expense Detail Required" := ExpenseReportLine."Expense Detail Required"::Participants;
        ExpenseReportLine.Modify();

        // [GIVEN] Create Expense Report Line Participant.
        CreateExpenseReportLineParticipant(ExpenseReportLineParticip, ExpenseReportLine);

        // [GIVEN] Save the setup so the declined change can be rolled back.
        Commit();

        // [WHEN] Update "Expense Category" in Expense Report Line and decline the deletion of associated records.
        asserterror ExpenseReportLine.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is not changed in the Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseCategory.Code, ExpenseReportLine."Expense Category", StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Category"), ExpenseCategory.Code, ExpenseReportLine.TableCaption()));

        // [THEN] Verify that the associated Participant is kept.
        ExpenseReportLineParticip.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportLineParticip, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportLinePerDiemDeletedWhenExpenseCategoryChangedAndConfirmed()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO 639727] Per Diem records on an Expense Report Line are deleted when the Expense Category is changed and the user confirms.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category with Reimbursement Type "Employee Paid".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);

        // [GIVEN] Release the Expense.
        Expense.PerformManualRelease();

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Add the Expense to the Expense Report.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [GIVEN] Find the Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");

        // [GIVEN] Set the line's required detail to Per Diem so the associated Per Diem is detected when the category changes.
        ExpenseReportLine."Expense Detail Required" := ExpenseReportLine."Expense Detail Required"::"Per Diem";
        ExpenseReportLine.Modify();

        // [GIVEN] Create Expense Report Line Per Diem.
        LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, '', WorkDate(), false, false, false, 10);

        // [WHEN] Update "Expense Category" in Expense Report Line and confirm the deletion of associated records.
        ExpenseReportLine.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is cleared in the Expense Report Line.
        Assert.AreEqual('', ExpenseReportLine."Expense Category", StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Category"), '', ExpenseReportLine.TableCaption()));

        // [THEN] Verify that the associated Per Diem is deleted.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure ExpenseReportLinePerDiemKeptWhenExpenseCategoryChangedAndNotConfirmed()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO 639727] Per Diem records on an Expense Report Line are kept when the Expense Category change is not confirmed.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category with Reimbursement Type "Employee Paid".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);

        // [GIVEN] Release the Expense.
        Expense.PerformManualRelease();

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Add the Expense to the Expense Report.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [GIVEN] Find the Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");

        // [GIVEN] Set the line's required detail to Per Diem so the associated Per Diem is detected when the category changes.
        ExpenseReportLine."Expense Detail Required" := ExpenseReportLine."Expense Detail Required"::"Per Diem";
        ExpenseReportLine.Modify();

        // [GIVEN] Create Expense Report Line Per Diem.
        LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, '', WorkDate(), false, false, false, 10);

        // [GIVEN] Save the setup so the declined change can be rolled back.
        Commit();

        // [WHEN] Update "Expense Category" in Expense Report Line and decline the deletion of associated records.
        asserterror ExpenseReportLine.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is not changed in the Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseCategory.Code, ExpenseReportLine."Expense Category", StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Category"), ExpenseCategory.Code, ExpenseReportLine.TableCaption()));

        // [THEN] Verify that the associated Per Diem is kept.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 1);
    end;

    [Test]
    procedure ExpenseReportLineAssociatedRecordsAutoDeletedWhenCategoryChangedWithHiddenValidation()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO 639727] Associated records are auto-deleted without a confirmation when the validation dialog is hidden (agent scenario).
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category with Reimbursement Type "Employee Paid".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);

        // [GIVEN] Release the Expense.
        Expense.PerformManualRelease();

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Add the Expense to the Expense Report.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [GIVEN] Find the Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");

        // [GIVEN] Create Expense Report Line Itemization.
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, WorkDate(), 10, 1);

        // [GIVEN] Hide the validation dialog to simulate the Expense Agent path.
        ExpenseReportLine.SetHideValidationDialog(true);

        // [WHEN] Update "Expense Category" in Expense Report Line.
        ExpenseReportLine.Validate("Expense Category", '');

        // [THEN] Verify that the "Expense Category" is cleared in the Expense Report Line.
        Assert.AreEqual('', ExpenseReportLine."Expense Category", StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Category"), '', ExpenseReportLine.TableCaption()));

        // [THEN] Verify that the associated Itemization is deleted automatically.
        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportLineItem, 0);
    end;

    [Test]
    procedure RelinkExpenseReportLineMustAssignNextLineNoInTargetReport()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExistingTargetExpenseReportLine: Record "Expense Report Line";
        CreateExpReport: Codeunit "Create Expense Report";
        ExpectedTargetLineNo: Integer;
    begin
        // [SCENARIO] Verify relinking assigns next available line no. in target report.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Create one existing line in target report.
        LibraryExpense.CreateExpenseReportLine(ExistingTargetExpenseReportLine, TargetExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', 50);
        ExpectedTargetLineNo := ExistingTargetExpenseReportLine."Line No." + 10000;

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");

        // [WHEN] Move line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        // [THEN] Verify moved line gets next target line no.
        Assert.AreEqual(
            ExpectedTargetLineNo,
            ExpenseReportLine."Line No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Line No."), ExpectedTargetLineNo, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure RelinkExpenseReportLineMustMoveThreeParticipants()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        CreateExpReport: Codeunit "Create Expense Report";
        SourceLineNo: Integer;
        TargetLineNo: Integer;
        Index: Integer;
    begin
        // [SCENARIO] Verify relinking moves 3 participants from source line to target line.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");
        SourceLineNo := ExpenseReportLine."Line No.";

        // [GIVEN] Create 3 participants on source line.
        for Index := 1 to 3 do
            CreateExpenseReportLineParticipant(ExpenseReportLineParticip, ExpenseReportLine);

        // [WHEN] Relink line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        TargetLineNo := ExpenseReportLine."Line No.";

        // [THEN] Verify source participants removed.
        ExpenseReportLineParticip.SetRange("Expense Report No.", SourceExpenseReportHeader."No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", SourceLineNo);
        Assert.RecordCount(ExpenseReportLineParticip, 0);

        // [THEN] Verify target participants count is 3.
        ExpenseReportLineParticip.SetRange("Expense Report No.", TargetExpenseReportHeader."No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", TargetLineNo);
        Assert.RecordCount(ExpenseReportLineParticip, 3);
    end;

    [Test]
    procedure RelinkExpenseReportLineMustMoveThreeItemizations()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        CreateExpReport: Codeunit "Create Expense Report";
        SourceLineNo: Integer;
        TargetLineNo: Integer;
        Index: Integer;
    begin
        // [SCENARIO] Verify relinking moves 3 itemizations from source line to target line.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");
        SourceLineNo := ExpenseReportLine."Line No.";

        // [GIVEN] Create 3 itemizations on source line.
        for Index := 1 to 3 do
            LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, WorkDate(), 10 * Index, 1);

        // [WHEN] Relink line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        TargetLineNo := ExpenseReportLine."Line No.";

        // [THEN] Verify source itemizations removed.
        ExpenseReportLineItem.SetRange("Expense Report No.", SourceExpenseReportHeader."No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", SourceLineNo);
        Assert.RecordCount(ExpenseReportLineItem, 0);

        // [THEN] Verify target itemizations count is 3.
        ExpenseReportLineItem.SetRange("Expense Report No.", TargetExpenseReportHeader."No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", TargetLineNo);
        Assert.RecordCount(ExpenseReportLineItem, 3);
    end;

    [Test]
    procedure RelinkExpenseReportLineMustMoveThreePerDiems()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        CreateExpReport: Codeunit "Create Expense Report";
        SourceLineNo: Integer;
        TargetLineNo: Integer;
        Index: Integer;
    begin
        // [SCENARIO] Verify relinking moves 3 per diem records from source line to target line.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");
        SourceLineNo := ExpenseReportLine."Line No.";

        // [GIVEN] Create 3 per diem records on source line.
        for Index := 1 to 3 do
            LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, '', WorkDate() + Index, false, false, false, 10 * Index);

        // [WHEN] Relink line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        TargetLineNo := ExpenseReportLine."Line No.";

        // [THEN] Verify source per diem records removed.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", SourceExpenseReportHeader."No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", SourceLineNo);
        Assert.RecordCount(ExpenseReportLinePerDiem, 0);

        // [THEN] Verify target per diem records count is 3.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", TargetExpenseReportHeader."No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", TargetLineNo);
        Assert.RecordCount(ExpenseReportLinePerDiem, 3);
    end;

    [Test]
    procedure RelinkExpenseReportLineMustMoveThreeAttachments()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        DocumentAttachment: Record "Document Attachment";
        CreateExpReport: Codeunit "Create Expense Report";
        SourceLineNo: Integer;
        TargetLineNo: Integer;
        Index: Integer;
        RelinkMoveAttachmentFileNameLbl: Label 'RelinkMove-%1.txt', Comment = '%1 = Sequence number';
    begin
        // [SCENARIO] Verify relinking moves 3 attachments from source line to target line.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");
        SourceLineNo := ExpenseReportLine."Line No.";

        // [GIVEN] Create 3 attachments on source line.
        for Index := 1 to 3 do
            CreateDocumentAttachmentForExpenseReportLine(DocumentAttachment, ExpenseReportLine, StrSubstNo(RelinkMoveAttachmentFileNameLbl, Index));

        // [WHEN] Relink line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        TargetLineNo := ExpenseReportLine."Line No.";

        // [THEN] Verify source attachments removed.
        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        DocumentAttachment.SetRange("No.", SourceExpenseReportHeader."No.");
        DocumentAttachment.SetRange("Line No.", SourceLineNo);
        Assert.RecordCount(DocumentAttachment, 0);

        // [THEN] Verify target attachments count is 3.
        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        DocumentAttachment.SetRange("No.", TargetExpenseReportHeader."No.");
        DocumentAttachment.SetRange("Line No.", TargetLineNo);
        Assert.RecordCount(DocumentAttachment, 3);
    end;

    [Test]
    procedure RelinkExpenseReportLineMustFailWhenTargetReportIsNotOpen()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO] Verify relinking fails when target expense report is not Open.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports, then set target status to Released.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        TargetExpenseReportHeader.Status := TargetExpenseReportHeader.Status::Released;
        TargetExpenseReportHeader.Modify(true);

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");

        // [WHEN] Move line to non-open target report.
        asserterror ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        // [THEN] Verify status validation error is raised for target report.
        Assert.ExpectedTestFieldError(TargetExpenseReportHeader.FieldCaption(Status), Format(TargetExpenseReportHeader.Status::Open));
    end;

    [Test]
    procedure RelinkExpenseReportLineMustFailWhenExpenseUsersDiffer()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        SourceExpenseUser: Record "Expense User";
        TargetExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO] Verify relinking fails when source and target report users are different.
        Initialize();

        // [GIVEN] Create users, master data and a released expense for source user.
        LibraryExpense.CreateExpenseUser(SourceExpenseUser);
        LibraryExpense.CreateExpenseUser(TargetExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, SourceExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports for different expense users.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, SourceExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, TargetExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");

        // [WHEN] Move line to report owned by a different expense user.
        asserterror ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        // [THEN] Verify expense user consistency validation error is raised.
        Assert.ExpectedTestFieldError(SourceExpenseReportHeader.FieldCaption("Expense User No."), TargetExpenseReportHeader."Expense User No.");
    end;

    [Test]
    procedure RelinkExpenseReportLineMustMoveExpenseAttachments()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        DocumentAttachment: Record "Document Attachment";
        ExpenseDocAttachment: Record "Document Attachment";
        LineDocAttachment: Record "Document Attachment";
        CreateExpReport: Codeunit "Create Expense Report";
        SourceLineNo: Integer;
        TargetLineNo: Integer;
        Index: Integer;
        ExpenseAttachmentFileNameLbl: Label 'ExpenseAttachment-%1.txt', Comment = '%1 = Sequence number';
    begin
        // [SCENARIO] Verify relinking moves attachments including those originating from the linked expense.
        Initialize();

        // [GIVEN] Create master data and expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);

        // [GIVEN] Create 2 attachments on the expense.
        for Index := 1 to 2 do
            CreateDocumentAttachmentForExpense(DocumentAttachment, Expense, StrSubstNo(ExpenseAttachmentFileNameLbl, Index));
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Add expense to source report (copies 2 attachment entries from expense to line).
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");
        SourceLineNo := ExpenseReportLine."Line No.";

        // [GIVEN] Add 1 more attachment directly on the expense report line.
        CreateDocumentAttachmentForExpenseReportLine(DocumentAttachment, ExpenseReportLine, 'LineAttachment.txt');

        // [GIVEN] Verify line has 3 attachments total.
        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        DocumentAttachment.SetRange("No.", SourceExpenseReportHeader."No.");
        DocumentAttachment.SetRange("Line No.", SourceLineNo);
        Assert.RecordCount(DocumentAttachment, 3);

        // [WHEN] Relink line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        TargetLineNo := ExpenseReportLine."Line No.";

        // [THEN] Verify source attachments removed.
        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        DocumentAttachment.SetRange("No.", SourceExpenseReportHeader."No.");
        DocumentAttachment.SetRange("Line No.", SourceLineNo);
        Assert.RecordCount(DocumentAttachment, 0);

        // [THEN] Verify target attachments count is 3.
        DocumentAttachment.SetRange("No.", TargetExpenseReportHeader."No.");
        DocumentAttachment.SetRange("Line No.", TargetLineNo);
        Assert.RecordCount(DocumentAttachment, 3);

        // [THEN] Verify original expense still has its 2 attachments.
        DocumentAttachment.SetRange("Table ID", Database::Expense);
        DocumentAttachment.SetRange("No.", Expense."No.");
        DocumentAttachment.SetRange("Line No.", 0);
        Assert.RecordCount(DocumentAttachment, 2);

        // [THEN] Verify expense-originated attachments on target line share the same Document Reference ID as the expense attachments.
        ExpenseDocAttachment.SetRange("Table ID", Database::Expense);
        ExpenseDocAttachment.SetRange("No.", Expense."No.");
        if ExpenseDocAttachment.FindSet() then
            repeat
                LineDocAttachment.SetRange("Table ID", Database::"Expense Report Line");
                LineDocAttachment.SetRange("No.", TargetExpenseReportHeader."No.");
                LineDocAttachment.SetRange("Line No.", TargetLineNo);
                LineDocAttachment.SetRange("Document Reference ID", ExpenseDocAttachment."Document Reference ID");
                Assert.RecordCount(LineDocAttachment, 1);
            until ExpenseDocAttachment.Next() = 0;
    end;

    [Test]
    procedure RelinkExpenseReportLineMustFailWhenSourceReportIsNotOpen()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO] Verify relinking fails when source expense report is not Open.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");

        // [GIVEN] Set source report to Released.
        SourceExpenseReportHeader.Status := SourceExpenseReportHeader.Status::Released;
        SourceExpenseReportHeader.Modify(true);

        // [WHEN] Try to move line from non-open source report.
        asserterror ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        // [THEN] Verify status validation error is raised for source report.
        Assert.ExpectedTestFieldError(SourceExpenseReportHeader.FieldCaption(Status), Format(SourceExpenseReportHeader.Status::Open));
    end;

    [Test]
    procedure RelinkExpenseReportLineMustFailWhenRelinkingToSameReport()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO] Verify relinking fails when renaming to the same expense report.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create expense report and add expense to it.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");

        // [WHEN] Try to move line to the same expense report.
        asserterror ExpenseReportLine.MoveToExpenseReport(ExpenseReportHeader."No.");

        // [THEN] Verify error about only relinking to another report.
        Assert.ExpectedError('You can only relink an expense report line to another expense report');
    end;

    [Test]
    procedure RelinkExpenseReportLineMustMoveThreeCommentLines()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
        CreateExpReport: Codeunit "Create Expense Report";
        SourceLineNo: Integer;
        TargetLineNo: Integer;
        Index: Integer;
        CommentLbl: Label 'Comment %1', Comment = '%1 = Sequence number';
    begin
        // [SCENARIO] Verify relinking moves 3 comment lines from source line to target line.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");
        SourceLineNo := ExpenseReportLine."Line No.";

        // [GIVEN] Create 3 comment lines on source line.
        for Index := 1 to 3 do
            CreateExpenseReportLineComment(ExpenseReportLine, CopyStr(StrSubstNo(CommentLbl, Index), 1, 80));

        // [WHEN] Relink line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        TargetLineNo := ExpenseReportLine."Line No.";

        // [THEN] Verify source comment lines removed.
        ExpenseReportCommentLine.SetRange("Document Type", ExpenseReportCommentLine."Document Type"::"Expense Report");
        ExpenseReportCommentLine.SetRange("No.", SourceExpenseReportHeader."No.");
        ExpenseReportCommentLine.SetRange("Document Line No.", SourceLineNo);
        Assert.RecordCount(ExpenseReportCommentLine, 0);

        // [THEN] Verify target comment lines count is 3.
        ExpenseReportCommentLine.SetRange("No.", TargetExpenseReportHeader."No.");
        ExpenseReportCommentLine.SetRange("Document Line No.", TargetLineNo);
        Assert.RecordCount(ExpenseReportCommentLine, 3);
    end;

    [Test]
    procedure RelinkExpenseReportLineMustRecalculateAmountsForTargetCurrency()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpReport: Codeunit "Create Expense Report";
        ExpenseCurrencyCode: Code[10];
        LineCurrencyCode: Code[10];
        SourceReimbCurrencyCode: Code[10];
        TargetReimbCurrencyCode: Code[10];
        SourceReimbursableAmount: Decimal;
    begin
        // [SCENARIO] Verify moving a line preserves line currency and recalculates reimbursable amount for target header currency.
        Initialize();

        // [GIVEN] Create currencies: A for expense, B for line override, X for source report, Y for target report.
        ExpenseCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        LineCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 2);
        SourceReimbCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 2, 1);
        TargetReimbCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 4, 1);

        // [GIVEN] Create master data and a released expense with currency A, Amount = 100.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, ExpenseCurrencyCode, 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source report with reimbursement currency X and target with Y.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", SourceReimbCurrencyCode, Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", TargetReimbCurrencyCode, Expense."VAT Bus. Posting Group");

        // [GIVEN] Add expense to source report, then change line expense currency to B.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");
        ExpenseReportLine.Validate("Expense Currency Code", LineCurrencyCode);
        ExpenseReportLine.Modify(true);
        SourceReimbursableAmount := ExpenseReportLine."Reimbursable Amount";

        // [WHEN] Move line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        // [THEN] Verify line expense currency is preserved as B.
        Assert.AreEqual(
            LineCurrencyCode,
            ExpenseReportLine."Expense Currency Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Currency Code"), LineCurrencyCode, ExpenseReportLine.TableCaption()));

        // [THEN] Verify reimbursable amount changed (now calculated against target currency Y instead of source X).
        Assert.AreNotEqual(
            SourceReimbursableAmount,
            ExpenseReportLine."Reimbursable Amount",
            'Reimbursable Amount should be recalculated for the target reimbursement currency.');

        // [THEN] Verify target header reimbursable amount reflects the moved line.
        TargetExpenseReportHeader.CalcFields("Reimbursable Amount");
        Assert.AreEqual(
            ExpenseReportLine."Reimbursable Amount",
            TargetExpenseReportHeader."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, TargetExpenseReportHeader.FieldCaption("Reimbursable Amount"), ExpenseReportLine."Reimbursable Amount", TargetExpenseReportHeader.TableCaption()));

        // [THEN] Verify source header reimbursable amount is zero (no lines remain).
        SourceExpenseReportHeader.CalcFields("Reimbursable Amount");
        Assert.AreEqual(
            0,
            SourceExpenseReportHeader."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, SourceExpenseReportHeader.FieldCaption("Reimbursable Amount"), 0, SourceExpenseReportHeader.TableCaption()));
    end;

    [Test]
    procedure RelinkExpenseReportLineMustUpdateHeaderAmounts()
    var
        Expense: array[5] of Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpReport: Codeunit "Create Expense Report";
        SourceReimbCurrencyCode: Code[10];
        TargetReimbCurrencyCode: Code[10];
        ExpectedSourceTotal: Decimal;
        ExpectedTargetTotal: Decimal;
        Index: Integer;
        ExpenseAmounts: array[5] of Decimal;
    begin
        // [SCENARIO] Verify moving 3 of 5 lines updates reimbursable amounts on both source and target headers with different currencies.
        Initialize();

        // [GIVEN] Create currencies: source reimb 1:1, target reimb 2:1.
        SourceReimbCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        TargetReimbCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 2, 1);

        // [GIVEN] Create master data and 5 released expenses (LCY) with amounts 100, 200, 300, 400, 500.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        ExpenseAmounts[1] := 100;
        ExpenseAmounts[2] := 200;
        ExpenseAmounts[3] := 300;
        ExpenseAmounts[4] := 400;
        ExpenseAmounts[5] := 500;
        for Index := 1 to 5 do begin
            LibraryExpense.CreateExpense(Expense[Index], ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', ExpenseAmounts[Index]);
            Expense[Index].PerformManualRelease();
        end;

        // [GIVEN] Create source report (reimb currency X) with all 5 expenses, and empty target report (reimb currency Y).
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", SourceReimbCurrencyCode, Expense[1]."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", TargetReimbCurrencyCode, Expense[1]."VAT Bus. Posting Group");
        for Index := 1 to 5 do
            CreateExpReport.AddSingleExpenseToExpenseReport(Expense[Index], SourceExpenseReportHeader);

        // [WHEN] Move expenses 1, 3, 5 (amounts 100, 300, 500) to target report.
        FindExpenseReportLine(ExpenseReportLine, Expense[1]);
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        FindExpenseReportLine(ExpenseReportLine, Expense[3]);
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        FindExpenseReportLine(ExpenseReportLine, Expense[5]);
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        // [THEN] Verify source header equals sum of remaining lines (expenses 2, 4).
        ExpectedSourceTotal := 0;
        for Index := 1 to 5 do
            if (Index = 2) or (Index = 4) then begin
                FindExpenseReportLine(ExpenseReportLine, Expense[Index]);
                ExpectedSourceTotal += ExpenseReportLine."Reimbursable Amount";
            end;
        SourceExpenseReportHeader.CalcFields("Reimbursable Amount");
        Assert.AreEqual(
            ExpectedSourceTotal,
            SourceExpenseReportHeader."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, SourceExpenseReportHeader.FieldCaption("Reimbursable Amount"), ExpectedSourceTotal, SourceExpenseReportHeader.TableCaption()));

        // [THEN] Verify target header equals sum of moved lines (expenses 1, 3, 5).
        ExpectedTargetTotal := 0;
        for Index := 1 to 5 do
            if (Index = 1) or (Index = 3) or (Index = 5) then begin
                FindExpenseReportLine(ExpenseReportLine, Expense[Index]);
                ExpectedTargetTotal += ExpenseReportLine."Reimbursable Amount";
            end;
        TargetExpenseReportHeader.CalcFields("Reimbursable Amount");
        Assert.AreEqual(
            ExpectedTargetTotal,
            TargetExpenseReportHeader."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, TargetExpenseReportHeader.FieldCaption("Reimbursable Amount"), ExpectedTargetTotal, TargetExpenseReportHeader.TableCaption()));
    end;

    [Test]
    procedure RelinkDirectExpenseReportLineMustMoveWithoutLinkedExpense()
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CurrencyCode: Code[10];
        OriginalAmount: Decimal;
        OriginalDescription: Text[100];
    begin
        // [SCENARIO] Verify moving a line created directly (no linked expense) works correctly.
        Initialize();

        // [GIVEN] Create master data.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        // [GIVEN] Create a line directly on the source report (no linked expense).
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, SourceExpenseReportHeader, ExpenseUser."No.",
            ExpenseCategory.Code, ExpensePaymentMethod.Code, true, CurrencyCode, 250);
        OriginalAmount := ExpenseReportLine.Amount;
        OriginalDescription := ExpenseReportLine.Description;

        // [WHEN] Move line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        // [THEN] Verify line has no linked expense.
        Assert.AreEqual(
            '',
            ExpenseReportLine."Expense No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense No."), '', ExpenseReportLine.TableCaption()));

        // [THEN] Verify line fields are preserved.
        Assert.AreEqual(
            OriginalAmount,
            ExpenseReportLine.Amount,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption(Amount), OriginalAmount, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            OriginalDescription,
            ExpenseReportLine.Description,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption(Description), OriginalDescription, ExpenseReportLine.TableCaption()));

        // [THEN] Verify line is on target report.
        Assert.AreEqual(
            TargetExpenseReportHeader."No.",
            ExpenseReportLine."Document No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Document No."), TargetExpenseReportHeader."No.", ExpenseReportLine.TableCaption()));

        // [THEN] Verify source report has no lines.
        SourceExpenseReportHeader.CalcFields("Reimbursable Amount");
        Assert.AreEqual(
            0,
            SourceExpenseReportHeader."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, SourceExpenseReportHeader.FieldCaption("Reimbursable Amount"), 0, SourceExpenseReportHeader.TableCaption()));

        // [THEN] Verify target header amount matches the moved line.
        TargetExpenseReportHeader.CalcFields("Reimbursable Amount");
        Assert.AreEqual(
            ExpenseReportLine."Reimbursable Amount",
            TargetExpenseReportHeader."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, TargetExpenseReportHeader.FieldCaption("Reimbursable Amount"), ExpenseReportLine."Reimbursable Amount", TargetExpenseReportHeader.TableCaption()));
    end;

    [Test]
    procedure RelinkExpenseReportLineMustPreserveDimensionSet()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        CreateExpReport: Codeunit "Create Expense Report";
        CurrencyCode: Code[10];
        OriginalDimensionSetID: Integer;
    begin
        // [SCENARIO] Verify moving a line preserves custom dimension set assigned on the line.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [GIVEN] Add expense to source report and set custom dimensions on the line.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");
        LibraryDimension.GetGlobalDimCodeValue(1, DimValue1);
        LibraryDimension.GetGlobalDimCodeValue(2, DimValue2);
        ExpenseReportLine.Validate("Shortcut Dimension 1 Code", DimValue1.Code);
        ExpenseReportLine.Validate("Shortcut Dimension 2 Code", DimValue2.Code);
        ExpenseReportLine.Modify();
        OriginalDimensionSetID := ExpenseReportLine."Dimension Set ID";

        // [WHEN] Move line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        // [THEN] Verify dimension set ID is preserved.
        Assert.AreEqual(
            OriginalDimensionSetID,
            ExpenseReportLine."Dimension Set ID",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Dimension Set ID"), OriginalDimensionSetID, ExpenseReportLine.TableCaption()));

        // [THEN] Verify shortcut dimension codes are preserved.
        Assert.AreEqual(
            DimValue1.Code,
            ExpenseReportLine."Shortcut Dimension 1 Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Shortcut Dimension 1 Code"), DimValue1.Code, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            DimValue2.Code,
            ExpenseReportLine."Shortcut Dimension 2 Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Shortcut Dimension 2 Code"), DimValue2.Code, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure RelinkExpenseReportLineMustPreservePerDiemMealFlags()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        CreateExpReport: Codeunit "Create Expense Report";
        TargetLineNo: Integer;
    begin
        // [SCENARIO] Verify moving a line preserves per diem Breakfast/Lunch/Dinner flags.
        Initialize();

        // [GIVEN] Create master data and a released expense.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.PerformManualRelease();

        // [GIVEN] Create source and target reports.
        LibraryExpense.CreateExpenseReport(SourceExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Create source line from expense.
        CreateExpReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        FindExpenseReportLine(ExpenseReportLine, SourceExpenseReportHeader."No.");

        // [GIVEN] Create 3 per diem records with different meal flag combinations.
        LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, '', WorkDate() + 1, true, true, false, 10);
        LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, '', WorkDate() + 2, false, true, true, 20);
        LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, '', WorkDate() + 3, true, false, true, 30);

        // [WHEN] Move line to target report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        TargetLineNo := ExpenseReportLine."Line No.";

        // [THEN] Verify 3 per diem records exist on target.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", TargetExpenseReportHeader."No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", TargetLineNo);
        Assert.RecordCount(ExpenseReportLinePerDiem, 3);

        // [THEN] Verify per diem records by iterating in PK order.
        ExpenseReportLinePerDiem.FindSet();

        // [THEN] Verify per diem 1 (Day+1): Breakfast=true, Lunch=true, Dinner=false.
        Assert.AreEqual(WorkDate() + 1, ExpenseReportLinePerDiem.Date, 'Per Diem Day+1: Date should be WorkDate+1.');
        Assert.IsTrue(ExpenseReportLinePerDiem.Breakfast, 'Per Diem Day+1: Breakfast should be true.');
        Assert.IsTrue(ExpenseReportLinePerDiem.Lunch, 'Per Diem Day+1: Lunch should be true.');
        Assert.IsFalse(ExpenseReportLinePerDiem.Dinner, 'Per Diem Day+1: Dinner should be false.');

        // [THEN] Verify per diem 2 (Day+2): Breakfast=false, Lunch=true, Dinner=true.
        ExpenseReportLinePerDiem.Next();
        Assert.AreEqual(WorkDate() + 2, ExpenseReportLinePerDiem.Date, 'Per Diem Day+2: Date should be WorkDate+2.');
        Assert.IsFalse(ExpenseReportLinePerDiem.Breakfast, 'Per Diem Day+2: Breakfast should be false.');
        Assert.IsTrue(ExpenseReportLinePerDiem.Lunch, 'Per Diem Day+2: Lunch should be true.');
        Assert.IsTrue(ExpenseReportLinePerDiem.Dinner, 'Per Diem Day+2: Dinner should be true.');

        // [THEN] Verify per diem 3 (Day+3): Breakfast=true, Lunch=false, Dinner=true.
        ExpenseReportLinePerDiem.Next();
        Assert.AreEqual(WorkDate() + 3, ExpenseReportLinePerDiem.Date, 'Per Diem Day+3: Date should be WorkDate+3.');
        Assert.IsTrue(ExpenseReportLinePerDiem.Breakfast, 'Per Diem Day+3: Breakfast should be true.');
        Assert.IsFalse(ExpenseReportLinePerDiem.Lunch, 'Per Diem Day+3: Lunch should be false.');
        Assert.IsTrue(ExpenseReportLinePerDiem.Dinner, 'Per Diem Day+3: Dinner should be true.');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure BillableLineKeepsHeaderDimensions()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        Customer: Record Customer;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO 580546] Verify that making a line Billable does not alter inherited shortcut dimensions.
        Initialize();

        // [GIVEN] Create and release an Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(50));
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Assign header dimensions.
        LibraryDimension.GetGlobalDimCodeValue(1, DimValue1);
        LibraryDimension.GetGlobalDimCodeValue(2, DimValue2);
        ExpenseReportHeader.Validate("Shortcut Dimension 1 Code", DimValue1.Code);
        ExpenseReportHeader.Validate("Shortcut Dimension 2 Code", DimValue2.Code);
        ExpenseReportHeader.Modify();

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [WHEN] Mark line Billable.
        LibrarySales.CreateCustomer(Customer);
        ExpenseReportLine.Validate(Billable, true);
        ExpenseReportLine.Validate("Billable to Customer", Customer."No.");
        ExpenseReportLine.Validate("Account Type", ExpenseReportLine."Account Type"::"G/L Account");
        ExpenseReportLine.Validate("Account No.", LibraryERM.CreateGLAccountNo());
        ExpenseReportLine.Modify();

        // [THEN] Verify line dimensions unchanged from header.
        Assert.AreEqual(
            ExpenseReportHeader."Shortcut Dimension 1 Code",
            ExpenseReportLine."Shortcut Dimension 1 Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Shortcut Dimension 1 Code"), ExpenseReportHeader."Shortcut Dimension 1 Code", ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ExpenseReportHeader."Shortcut Dimension 2 Code",
            ExpenseReportLine."Shortcut Dimension 2 Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Shortcut Dimension 2 Code"), ExpenseReportHeader."Shortcut Dimension 2 Code", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure PurchaseInvoiceResetClearsVendorFields()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        Expense: Record Expense;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        VendorNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that clearing Purchase Invoice on Expense Report Line clears "Vendor No." and "Posted Purch. Invoice No.".
        Initialize();

        // [GIVEN] Create and Release an Expense.
        CreateExpense(Expense, true, '', LibraryRandom.RandInt(50));
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Set Purchase Invoice true with vendor.
        VendorNo := LibraryPurchase.CreateVendorNo();
        ExpenseReportLine.Validate("Purchase Invoice", true);
        ExpenseReportLine.Validate("Vendor No.", VendorNo);
        ExpenseReportLine.Modify();

        // [WHEN] Set Purchase Invoice to false.
        ExpenseReportLine.Validate("Purchase Invoice", false);
        ExpenseReportLine.Modify();

        // [THEN] Verify Vendor No. and Posted Purch. Invoice No. cleared.
        Assert.AreEqual(
            '',
            ExpenseReportLine."Vendor No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Vendor No."), '', ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseReportLine."Posted Purch. Invoice No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Posted Purch. Invoice No."), '', ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure PostingDateDefaultsOnNewExpenseReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 580546] Verify that Posting Date and Expense Report Date default to WorkDate() on creation.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [THEN] Verify dates default.
        Assert.AreEqual(
            WorkDate(),
            ExpenseReportHeader."Posting Date",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Posting Date"), Format(WorkDate()), ExpenseReportHeader.TableCaption()));
        Assert.AreEqual(
            WorkDate(),
            ExpenseReportHeader."Expense Report Date",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption("Expense Report Date"), Format(WorkDate()), ExpenseReportHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportCannotBePostedWithoutLines()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 580546] Verify that Expense Report cannot be posted when it has no lines.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [WHEN] Attempt to post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify specific error about no lines.
        Assert.ExpectedError(StrSubstNo(ExpenseReportLineDoesNotExistErr, ExpenseReportHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure RefundableMustBeReflectedInExpenseReportLineFromExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO 613262] Verify that Refundable must be reflected in Expense Line from Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandInt(100));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [WHEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [THEN] Verify that Refundable is reflected in Expense Line from Expense.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        Assert.AreEqual(
            true,
            ExpenseReportLine.Refundable,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption(Refundable), true, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure RefundableMustBeReflectedInExpenseReportLineFromExpenseCategory()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO 613262] Verify that Refundable must be reflected in Expense Line from Expense Category.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandInt(100));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [WHEN] Insert Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, false, '',
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        // [THEN] Verify that Refundable is reflected in Expense Line from Expense Category.
        Assert.AreEqual(
            true,
            ExpenseReportLine.Refundable,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption(Refundable), true, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure RefundableMustBeReflectedInExpenseReportLineFromExpenseCategoryWhichIsFalse()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO 613262] Verify that Refundable must be reflected in Expense Line from Expense Category which is false.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Expense Category with Refundable set to false.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, false);
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandInt(100));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [WHEN] Insert Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, false, '',
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        // [THEN] Verify that Refundable is reflected in Expense Line from Expense Category which is false.
        Assert.AreEqual(
            false,
            ExpenseReportLine.Refundable,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption(Refundable), false, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure CannotReleaseExpenseReportIfRefundableIsFalseAndReimbursementTypeIsEmployeePaid()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ReleaseExpenseReportDocument: Codeunit "Release Exp. Report Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614287] Verify that Expense Report cannot be released if Refundable is false and Reimbursement Type is Employee Paid.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), '',
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [WHEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [THEN] Verify that the Reimbursement Amount is updated when Refundable is true and Type is Employee Paid.
        Assert.AreEqual(
            Amount,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), Amount, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            Expense."Amount (LCY)",
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), Expense."Amount (LCY)", ExpenseReportLine.TableCaption()));

        // [WHEN] Update Refundable in Expense Report Line.
        ExpenseReportLine.Validate(Refundable, false);
        ExpenseReportLine.Modify();

        // [THEN] Verify that the Reimbursement Amount is zero when Refundable is false and Type is Employee Paid.
        Assert.AreEqual(
            0,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), 0, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            0,
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), 0, ExpenseReportLine.TableCaption()));

        // [WHEN] Release Expense Report.
        asserterror ReleaseExpenseReportDocument.PerformManualRelease(ExpenseReportHeader);

        // [THEN] Verify that Expense Report cannot be released if Refundable is false and Reimbursement Type is Employee Paid.
        Assert.ExpectedError(StrSubstNo(CannotReleaseDocumentWithNothingToRefundErr, ExpenseReportHeader."No.", ExpenseReportLine."Line No."));
    end;

    [Test]
    procedure ReimbursementAmountIsZeroInExpenseReportLineIfReimbursementTypeIsCompanyPaid()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpectedAmountLCY, Amount : Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 614287] Verify that Expense Report Line Reimbursement Amount is zero if Reimbursement Type is Company Paid.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, Amount);

        // [THEN] Verify that the Reimbursement Amount is updated when Refundable is true and Type is Employee Paid.
        Assert.AreEqual(
            Amount,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), Amount, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ExpectedAmountLCY,
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), ExpectedAmountLCY, ExpenseReportLine.TableCaption()));

        // [GIVEN] Reopen Expense Report.
        ExpenseReportHeader.SetRange("No.", ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualReopen(ExpenseReportHeader);

        // [WHEN] Update "Reimbursement Type" in Expense Report Line.
        ExpenseReportLine.Validate("Reimbursement Type", ExpenseReportLine."Reimbursement Type"::"Company Paid");
        ExpenseReportLine.Validate("Payment Method Code", '');
        ExpenseReportLine.Modify();

        // [THEN] Verify that the Reimbursement Amount is zero when Refundable is false and Type is Employee Paid.
        Assert.AreEqual(
            0,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), 0, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            0,
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), 0, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure ReimbursementAmountIsZeroInExpenseReportLineIfReimbursementTypeIsCreditCard()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpectedAmountLCY, Amount : Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 614287] Verify that Expense Report Line Reimbursement Amount is zero if Reimbursement Type is Credit Card.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, Amount);

        // [THEN] Verify that the Reimbursement Amount is updated when Refundable is true and Type is Credit Paid.
        Assert.AreEqual(
            Amount,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), Amount, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ExpectedAmountLCY,
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), ExpectedAmountLCY, ExpenseReportLine.TableCaption()));

        // [WHEN] Update "Reimbursement Type" in Expense Report Line.
        ExpenseReportLine.Validate("Reimbursement Type", ExpenseReportLine."Reimbursement Type"::"Credit Card");
        ExpenseReportLine.Validate("Payment Method Code", '');
        ExpenseReportLine.Modify();

        // [THEN] Verify that the Reimbursement Amount is zero when Refundable is false and Type is Credit Card.
        Assert.AreEqual(
            0,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), 0, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            0,
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), 0, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReimbursementTypeMustBeRequiredWhenExpenseReportIsPosted()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmountLCY, Amount : Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 614287] Verify that Reimbursement Type must be required when Expense Report is posted.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, Amount);

        // [THEN] Verify that the Reimbursement Amount is updated when Refundable is true and Type is Credit Paid.
        Assert.AreEqual(
            Amount,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), Amount, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ExpectedAmountLCY,
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), ExpectedAmountLCY, ExpenseReportLine.TableCaption()));

        // [WHEN] Update "Reimbursement Type" in Expense Report Line.
        ExpenseReportLine.Validate("Reimbursement Type", ExpenseReportLine."Reimbursement Type"::" ");
        ExpenseReportLine.Validate("Payment Method Code", '');
        ExpenseReportLine.Modify();

        // [THEN] Verify that the Reimbursement Amount is zero when Refundable is false and Type is Credit Card.
        Assert.AreEqual(
            0,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), 0, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            0,
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), 0, ExpenseReportLine.TableCaption()));

        // [WHEN] Attempt to post Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Reimbursement Type must be required when Expense Report is posted.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Reimbursement Type"), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ReimbursementTypeEmployeePaidMustBeUpdatedFromExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613339] Verify that Reimbursement Type Employee Paid must be updated from Expense.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), '',
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [WHEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [THEN] Verify that the Reimbursement Type is Employee Paid from Expense.
        Assert.AreEqual(
            Expense."Reimbursement Type"::"Employee Paid",
            ExpenseReportLine."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursement Type"), Expense."Reimbursement Type"::"Employee Paid", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ReimbursementTypeCreditCardMustBeUpdatedFromExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613339] Verify that Reimbursement Type Credit Card must be updated from Expense.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Update Reimbursement Type to Credit Card in Expense.
        Expense.Validate("Reimbursement Type", Expense."Reimbursement Type"::"Credit Card");
        Expense.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [WHEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [THEN] Verify that the Reimbursement Type is Credit Card from Expense.
        Assert.AreEqual(
            Expense."Reimbursement Type"::"Credit Card",
            ExpenseReportLine."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursement Type"), Expense."Reimbursement Type"::"Credit Card", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ReimbursementTypeCompanyPaidMustBeUpdatedFromExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613339] Verify that Reimbursement Type Company Paid must be updated from Expense.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [WHEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [THEN] Verify that the Reimbursement Type is Company Paid from Expense.
        Assert.AreEqual(
            Expense."Reimbursement Type"::"Company Paid",
            ExpenseReportLine."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursement Type"), Expense."Reimbursement Type"::"Company Paid", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseStatusMustBeEqualToSubmittedWhenExpenseIsAddedInExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613384] Verify that Expense Status must be equal to Submitted when Expense is added in Expense Report.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Get Expense User.
        ExpenseUser.Get(Expense."Expense User No.");

        // [WHEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [THEN] Verify that the Expense Status is Submitted.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            Expense."Status"::Submitted,
            Expense."Status",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Status"), Expense."Status"::Submitted, Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseStatusMustBeEqualToReleasedWhenExpenseIsRemovedFromExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613384] Verify that Expense Status must be equal to Released when Expense is removed from Expense Report.
        // [ScENARIO 620061] Verify that Expense Status must be equal to Released when Expense Report Line is deleted.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [THEN] Verify that the Expense Status is Submitted.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            Expense."Status"::Submitted,
            Expense."Status",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Status"), Expense."Status"::Submitted, Expense.TableCaption()));

        // [GIVEN] Remove Expense Report Line per Diem from Expense Report.
        ExpenseReportLinePerDiem.SetRange("Expense No.", Expense."No.");
        ExpenseReportLinePerDiem.DeleteAll();

        // [WHEN] Delete Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        ExpenseReportLine.Delete(true);

        // [THEN] Verify that the Expense Status is Released.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            Expense."Status"::Released,
            Expense."Status",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Status"), Expense."Status"::Released, Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure DescriptionMustBeFlowFromExpenseInExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseSubcategory: Record "Expense Subcategory";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613294] Verify that Description must flow from Expense in Expense Report.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Update Description in Expense.
        Expense.Validate(Description, Format(Amount));
        Expense.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [THEN] Verify that the Description is flow from Expense to Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        ExpenseSubcategory.Get(Expense."Expense Category", Expense."Expense Subcategory");
        Assert.AreEqual(
            Format(Amount) + ' / ' + ExpenseSubcategory."Posting Description",
            ExpenseReportLine.Description,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Description"), Format(Amount), ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure PostingDescriptionUsesAvailableSubcategoryDescription()
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: array[2] of Record "Expense Subcategory";
        ExpenseReportLine: Record "Expense Report Line";
        BaseDescription: Text[100];
    begin
        // [SCENARIO] The posting description uses the selected subcategory description when it is available.
        Initialize();

        // [GIVEN] A report line whose description already includes its original subcategory description.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory[1], ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory[2], ExpenseCategory.Code, true);
        BaseDescription := ExpenseCategory."Posting Description";
        ExpenseReportLine."Expense Category" := ExpenseCategory.Code;
        ExpenseReportLine."Expense Subcategory Code" := ExpenseSubcategory[1].Code;
        ExpenseReportLine.Description := CopyStr(BaseDescription + ' / ' + ExpenseSubcategory[1]."Posting Description", 1, MaxStrLen(ExpenseReportLine.Description));

        // [WHEN] A different subcategory is used for posting.
        // [THEN] Its posting description replaces the original subcategory suffix.
        Assert.AreEqual(
            BaseDescription + ' / ' + ExpenseSubcategory[2]."Posting Description",
            ExpenseReportLine.UpdatePostingDescription(ExpenseCategory.Code, ExpenseSubcategory[2].Code),
            'The posting description must use the selected subcategory description.');

        // [WHEN] The original subcategory suffix was truncated by the description length limit.
        BaseDescription := PadStr('', 95, 'B');
        ExpenseSubcategory[1]."Posting Description" := 'OLD SUFFIX';
        ExpenseSubcategory[1].Modify();
        ExpenseSubcategory[2]."Posting Description" := 'NEW SUFFIX';
        ExpenseSubcategory[2].Modify();
        ExpenseReportLine.Description := CopyStr(BaseDescription + ' / ' + ExpenseSubcategory[1]."Posting Description", 1, MaxStrLen(ExpenseReportLine.Description));

        // [THEN] The stored part of the old suffix is removed before the new suffix is applied.
        Assert.AreEqual(
            CopyStr(BaseDescription + ' / ' + ExpenseSubcategory[2]."Posting Description", 1, MaxStrLen(ExpenseReportLine.Description)),
            ExpenseReportLine.UpdatePostingDescription(ExpenseCategory.Code, ExpenseSubcategory[2].Code),
            'The truncated posting-description suffix must be replaced.');

        // [WHEN] The selected subcategory has no posting description.
        ExpenseSubcategory[2]."Posting Description" := '';
        ExpenseSubcategory[2].Modify();

        // [THEN] The base description is retained without a separator.
        Assert.AreEqual(
            BaseDescription,
            ExpenseReportLine.UpdatePostingDescription(ExpenseCategory.Code, ExpenseSubcategory[2].Code),
            'The base posting description must be retained when the subcategory posting description is unavailable.');
    end;

    [Test]
    procedure DescriptionMustBeFlowFromExpenseCategoryInExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO 613294] Verify that Description must be flow from Expense Category in Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandInt(100));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [WHEN] Insert Expense Report Line.
        ExpenseReportLine.Init();
        ExpenseReportLine.Validate("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Insert();

        // [THEN] Verify that the Description is flow from Expense Category to Expense Report Line.
        Assert.AreEqual(
            ExpenseCategory."Posting Description",
            ExpenseReportLine.Description,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Description"), ExpenseCategory."Posting Description", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AmountReductionIsEditableWhenRefundableIsTrueInExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPage: TestPage "Expense Report";
        AmountReduction, Amount : Decimal;
    begin
        // [SCENARIO 613294] Verify that Amount Reduction is editable when Refundable is true in Expense Report.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandInt(10);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", false, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that the Amount Reduction is not calculated when Refundable is false in Expense Report Line.
        ExpenseReportPage."Expense Report Subform"."Refundable".AssertEquals(false);
        ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".AssertEquals(0);

        // [THEN] Verify that the Amount Reduction field is not editable when Refundable is false in Expense Report Line.
        Assert.AreEqual(
            false,
            ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".Caption(), ExpenseReportPage.Caption()));

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage."Expense Report Subform"."Refundable".SetValue(true);
        ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".SetValue(AmountReduction);

        // [THEN] Verify that the Amount Reduction field is editable when Refundable is true in Expense Report Line.
        Assert.AreEqual(
            true,
            ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".Caption(), ExpenseReportPage.Caption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AttestationMustNotBeVisibleWhenAntiCorruptionIsNotEnabled()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 613294] Verify that Attestation is not visible when Anti-Corruption is not enabled.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Disable Anti-Corruption in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Enable Anti-Corp. Statement" := false;
        ExpenseAgentSetup.Modify();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that the Attestation fields are not visible in Expense Report Page.
        Assert.AreEqual(
            false,
            ExpenseReportPage."Anti-Corruption Attestation".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpenseReportPage."Anti-Corruption Attestation".Caption(), ExpenseReportPage.Caption()));
        Assert.AreEqual(
            false,
            ExpenseReportPage."Anti-Corruption Description".Visible(),
            StrSubstNo(FieldShouldNotBeVisibleErr, ExpenseReportPage."Anti-Corruption Description".Caption(), ExpenseReportPage.Caption()));
        Assert.AreEqual(
            false,
            ExpenseReportPage.Corrected.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportPage.Corrected.Caption(), ExpenseReportPage.Caption()));
        Assert.AreEqual(
            false,
            ExpenseReportPage."Corrected Document No.".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportPage."Corrected Document No.".Caption(), ExpenseReportPage.Caption()));
        ExpenseReportPage.Close();

        // [GIVEN] Enable Anti-Corruption in Expense Agent Setup.
        ExpenseAgentSetup."Enable Anti-Corp. Statement" := true;
        ExpenseAgentSetup.Modify();

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);

        // [THEN] Verify that the Attestation fields are visible in Expense Report Page.
        Assert.AreEqual(
            true,
            ExpenseReportPage."Anti-Corruption Attestation".Visible(),
            StrSubstNo(FieldShouldBeVisibleErr, ExpenseReportPage."Anti-Corruption Attestation".Caption(), ExpenseReportPage.Caption()));
        Assert.AreEqual(
            true,
            ExpenseReportPage."Anti-Corruption Description".Visible(),
            StrSubstNo(FieldShouldBeVisibleErr, ExpenseReportPage."Anti-Corruption Description".Caption(), ExpenseReportPage.Caption()));
        ExpenseReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,AddExpensesToExpenseReportModalPageHandler')]
    procedure ExpenseDetailRequiredMustFlowFromExpenseToExpenseReport()
    var
        Expense: array[5] of Record Expense;
        ExpenseFilter: Record Expense;
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseSubCategory: Record "Expense Subcategory";
        CreateExpReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
    begin
        // [SCENARIO 613726] Verify that Expense Detail Required must flow from Expense to Expense Report.
        Initialize();

        // [GIVEN] Update Default Unit of Measure in Expense Agent Setup.
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(20, 100));
        ExpenseAgentSetup.Modify();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense[1], ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense[1]);

        // [GIVEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense[2], ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Mileage", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Min Amount", true, Amount);

        // [GIVEN] Update "Mileage" in Expense.
        Expense[2].Validate(Mileage, LibraryRandom.RandInt(10));
        Expense[2].Modify(true);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense[2]);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense[3], ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense[3]);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense[3]);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense[4], ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense[4]."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense[4], ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense[4]);

        // [GIVEN] Create and Release an Expense With Rule "None".
        CreateExpense(Expense[5], ExpenseUser, true, '', LibraryRandom.RandInt(50));
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense[5]);

        // [GIVEN] Set Expense User Filter To Expense.
        ExpenseFilter.SetRange("Expense User No.", ExpenseUser."No.");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense[1]."VAT Bus. Posting Group");

        // Enqueue Existing Expense Report No. and mark to skip creating a new one.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExpenseReportHeader."No.");

        // [WHEN] Insert Expenses.
        CreateExpReport.AddExpensesToReport(ExpenseFilter);

        // [THEN] Verify that the Expense Detail Required flows from Expense to Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense[1]);
        Assert.AreEqual(
            Expense[1]."Expense Detail Required",
            ExpenseReportLine."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Detail Required"), Expense[1]."Expense Detail Required", ExpenseReportLine.TableCaption()));

        FindExpenseReportLine(ExpenseReportLine, Expense[2]);
        Assert.AreEqual(
            Expense[2]."Expense Detail Required",
            ExpenseReportLine."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Detail Required"), Expense[2]."Expense Detail Required", ExpenseReportLine.TableCaption()));

        FindExpenseReportLine(ExpenseReportLine, Expense[3]);
        Assert.AreEqual(
            Expense[3]."Expense Detail Required",
            ExpenseReportLine."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Detail Required"), Expense[3]."Expense Detail Required", ExpenseReportLine.TableCaption()));

        FindExpenseReportLine(ExpenseReportLine, Expense[4]);
        Assert.AreEqual(
            Expense[4]."Expense Detail Required",
            ExpenseReportLine."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Detail Required"), Expense[4]."Expense Detail Required", ExpenseReportLine.TableCaption()));

        FindExpenseReportLine(ExpenseReportLine, Expense[5]);
        Assert.AreEqual(
            Expense[5]."Expense Detail Required",
            ExpenseReportLine."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Detail Required"), Expense[5]."Expense Detail Required", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ExpenseReportLineItemsEditableModalPageHandler')]
    procedure ExpenseReportItemizationPageMustBeEditableWhenExpenseReportIsCreatedFromExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613726] Verify that the Expense Report Itemization Page must be editable when Expense Report is created from Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), '',
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Show Itemization from Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        ExpenseReportLine.ShowItemization();

        // [THEN] Verify that Expense Report Itemization Page must be editable.
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ExpenseReportLinePerDiemEditableModalPageHandler')]
    procedure ExpenseReportPerDiemPageMustBeEditableWhenExpenseReportIsCreatedFromExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 613726] Verify that the Expense Report Per Diem Page must be editable when Expense Report is created from Expense.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", false, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [WHEN] Invoke Per Diem from Expense Report Line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that Expense Report Per Diem Page must be editable.
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ExpenseReportLineParticipantsEditableModalPageHandler')]
    procedure ExpenseReportParticipantPageMustBeEditableWhenExpenseReportIsCreatedFromExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613726] Verify that the Expense Report Participant Page must be editable when Expense Report is created from Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, '', '', CurrencyCode, Amount, WorkDate(), '',
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Release Expense.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Show Participants from Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        ExpenseReportLine.ShowParticipants();

        // [THEN] Verify that Expense Report Participant Page must be editable.
    end;

    [Test]
    procedure ReimbursementTypeMustBeUpdatedFromPaymentMethodCodeInExpenseReport()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod1: Record "Expense Payment Method";
        ExpensePaymentMethod2: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpectedAmountLCY, Amount : Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 616218] Verify that Reimbursement Type must be updated from Payment Method Code in Expense Report.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod1, "Expense Reimbursement Type"::"Company Paid");

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod2, "Expense Reimbursement Type"::"Employee Paid");

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, Amount);

        // [THEN] Verify that the Reimbursement Amount is updated when Refundable is true and Type is Employee Paid.
        Assert.AreEqual(
            Amount,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), Amount, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ExpectedAmountLCY,
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), ExpectedAmountLCY, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLine."Reimbursement Type"::"Employee Paid",
            ExpenseReportLine."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursement Type"), ExpenseReportLine."Reimbursement Type"::"Employee Paid", ExpenseReportLine.TableCaption()));

        // [WHEN] Update "Payment Method Code" in Expense Report Line.
        ExpenseReportLine.Validate("Payment Method Code", ExpensePaymentMethod2.Code);

        // [THEN] Verify that the Reimbursement Type is updated.
        Assert.AreEqual(
            ExpensePaymentMethod2."Reimbursement Type",
            ExpenseReportLine."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursement Type"), ExpensePaymentMethod2."Reimbursement Type", ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            Amount,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), Amount, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ExpectedAmountLCY,
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), ExpectedAmountLCY, ExpenseReportLine.TableCaption()));

        // [GIVEN] Reopen Expense Report.
        ExpenseReportHeader.SetRange("No.", ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualReopen(ExpenseReportHeader);

        // [WHEN] Update "Payment Method Code" in Expense Report Line.
        ExpenseReportLine.Validate("Payment Method Code", '');

        // [THEN] Verify that the Reimbursement Amount is zero when Refundable is false and Type is Employee Paid.
        Assert.AreEqual(
            0,
            ExpenseReportLine."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount"), 0, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            0,
            ExpenseReportLine."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursable Amount (LCY)"), 0, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLine."Reimbursement Type"::" ",
            ExpenseReportLine."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursement Type"), ExpenseReportLine."Reimbursement Type"::" ", ExpenseReportLine.TableCaption()));

        // [WHEN] Update "Payment Method Code" in Expense Report Line.
        ExpenseReportLine.Validate("Payment Method Code", ExpensePaymentMethod1.Code);

        // [THEN] Verify that the Reimbursement Type is updated.
        Assert.AreEqual(
            ExpensePaymentMethod1."Reimbursement Type",
            ExpenseReportLine."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Reimbursement Type"), ExpensePaymentMethod1."Reimbursement Type", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpenseReportLinePerDiemWithRuleModalPageHandler')]
    procedure FieldsAreEditableAndNonEditableInExpenseReportLinePerDiemPageWhenRuleIsApplied()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616946] Verify that the Expense Report Per Diem Page fields are editable and non-editable when Rule is applied.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Rule With Condition "Per Diem".
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", Amount);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        // [GIVEN] Create Expense Report Line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform"."Expense Location".SetValue(ExpenseLocation."No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the fields are editable and non-editable in Expense Report Line Per Diem Page when Rule is applied.
    end;

    [Test]
    [HandlerFunctions('NewPerDiemExpenseReportWithoutRuleModalPageErrorHandler')]
    procedure NewPerDiemEntryCannotBeCreatedWhenRuleIsAppliedFromExpenseReportPerDiemPage()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616946] Verify that the New Per Diem Entry cannot be created when Rule is applied from Expense Report Per Diem Page.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Rule With Condition "Per Diem".
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", Amount);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        // [GIVEN] Create Expense Report Line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform"."Expense Location".SetValue(ExpenseLocation."No.");

        // [GIVEN] Save Expense Report.
        Commit();

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the new Per Diem entry cannot be created when Rule is applied from Expense Report Line Per Diem Page through Handler.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 1);
    end;

    [Test]
    [HandlerFunctions('PerDiemExpenseReportWithNoRuleModalPageHandler')]
    procedure FieldsAreEditableInExpenseReportPerDiemPageWhenNoRuleIsApplied()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616946] Verify that the Expense Report Per Diem Page fields are editable when No Rule is applied.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        // [GIVEN] Create Expense Report Line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform"."Expense Location".SetValue(ExpenseLocation."No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the fields are editable in Expense Report Line Per Diem Page when No Rule is applied.
    end;

    [Test]
    [HandlerFunctions('NewPerDiemExpenseReportWithoutRuleModalPageErrorHandler')]
    procedure NewPerDiemEntryCannotBeCreatedWhenRuleIsNotAppliedFromExpenseReportPerDiemPage()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpenseReportPage: TestPage "Expense Report";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616946] Verify that the new Per Diem entry cannot be created when Rule is not applied from Expense Report Per Diem Page.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        // [GIVEN] Create Expense Report Line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform"."Expense Location".SetValue(ExpenseLocation."No.");

        // [GIVEN] Save Expense Report.
        Commit();

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the new Per Diem entry cannot be created when Rule is not applied from Expense Report Line Per Diem Page through Handler.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 0);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure CannotReleaseExpenseReportIfExpenseCategoryIsInactive()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseCategory: Record "Expense Category";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617001] Verify that Expense Report cannot be released if Expense Category is inactive.
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
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), '',
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Set Expense Category as Inactive.
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseCategory.Validate(Inactive, true);
        ExpenseCategory.Modify(true);

        // [WHEN] Release Expense.
        asserterror ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify that Expense Report cannot be released if Expense Category is inactive.
        Assert.ExpectedTestFieldError(ExpenseCategory.FieldCaption(Inactive), Format(false));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure CannotReleaseExpenseReportIfExpenseSubcategoryIsInactive()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617001] Verify that Expense Report cannot be released if Expense Subcategory is inactive.
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
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), '',
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Subcategory.
        ExpenseCategory.Get(Expense."Expense Category");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Update Expense Subcategory in Expense.
        Expense.Validate("Expense Subcategory", ExpenseSubCategory.Code);
        Expense.Validate("Expense Date", WorkDate());
        Expense.Modify(true);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Set Expense Subcategory as Inactive.
        ExpenseSubCategory.Validate(Inactive, true);
        ExpenseSubCategory.Modify(true);

        // [WHEN] Release Expense.
        asserterror ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify that Expense Report cannot be released if Expense Subcategory is inactive.
        Assert.ExpectedTestFieldError(ExpenseSubCategory.FieldCaption(Inactive), Format(false));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure CannotCreateExpenseReportIfExpenseCategoryIsInactive()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617001] Verify that Expense Report cannot be created if Expense Category is inactive.
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
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), '',
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [GIVEN] Set Expense Category as Inactive.
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseCategory.Validate(Inactive, true);
        ExpenseCategory.Modify(true);

        // [WHEN] Insert Expense.
        asserterror CreateExpReport.AddExpensesToReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report cannot be created if Expense Category is inactive.
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure CannotCreateExpenseReportIfExpenseSubcategoryIsInactive()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617001] Verify that Expense Report cannot be created if Expense Subcategory is inactive.
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
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(), '',
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Subcategory.
        ExpenseCategory.Get(Expense."Expense Category");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Update Expense Subcategory in Expense.
        Expense.Validate("Expense Subcategory", ExpenseSubCategory.Code);
        Expense.Validate("Expense Date", WorkDate());
        Expense.Modify(true);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [GIVEN] Set Expense Subcategory as Inactive.
        ExpenseSubCategory.Validate(Inactive, true);
        ExpenseSubCategory.Modify(true);

        // [WHEN] Insert Expense.
        asserterror CreateExpReport.AddExpensesToReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report cannot be created if Expense Subcategory is inactive.
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('AddExpenseItemizationsWithSubCategoryHandler')]
    procedure AmountReductionIsUpdatedInExpenseReportLineFromExpenseReportItemizationPage()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        AmountReduction: Decimal;
    begin
        // [SCENARIO 616971] Verify that the Amount Reduction is updated in Expense Report Line from Expense Report Itemization Page.
        // when Expense Report Line Itemization is created with Refundable and Non-Refundable Expense Sub Category.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandIntInRange(50, 90);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Sub Category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[1], ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[2], ExpenseCategory.Code, false);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, CopyStr(ExpenseReportPage."No.".Value, 1, 20));

        // [GIVEN] Update "Merchant Name" in Expense Report Line.
        ExpenseReportLine.Validate("Merchant Name", CopyStr(LibraryRandom.RandText(20), 1, 100));
        ExpenseReportLine.Modify();

        // [GIVEN] Enqueue Expense Sub Category Code, Quantity and Amount for Expense Itemization.
        LibraryVariableStorage.Enqueue(ExpenseSubCategory[1].Code);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(Amount - AmountReduction);

        LibraryVariableStorage.Enqueue(ExpenseSubCategory[2].Code);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(AmountReduction);

        // [GIVEN] Add Itemization from Expense Itemizations Page.
        ExpenseReportPage."Expense Report Subform".Itemizations.Invoke();

        // [WHEN] Release Expense Report.
        ExpenseReportPage.Release.Invoke();

        // [THEN] Verify that the Non-Refundable Amount is updated in Expense Report Line from Expense Report Itemization Page.
        ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".AssertEquals(AmountReduction);
        ExpenseReportPage.Status.AssertEquals(Format(ExpenseReportHeader.Status::Released));
    end;

    [Test]
    [HandlerFunctions('ExactMessageHandler,VerifyQuantityInExpenseReportItemizationsModalPageHandler')]
    procedure ItemizationTotalReductionMismatchInExpenseReportLineAndExpenseReportItemization()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpenseReportLineItemization: array[2] of Record "Expense Report Line Item";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        AmountReduction: Decimal;
    begin
        // [SCENARIO 616971] Verify that the Itemization Total Reduction Mismatch error is shown in Expense Report Line and Expense Report Itemization.
        // when Expense Report Line Itemization is created with Refundable and Non-Refundable Expense Sub Category
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandIntInRange(50, 90);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Sub Category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[1], ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[2], ExpenseCategory.Code, false);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, CopyStr(ExpenseReportPage."No.".Value, 1, 20));

        // [GIVEN] Create Expense Report Line Itemization with Refundable and Non-Refundable Expense Sub Category.
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItemization[1], ExpenseReportLine, ExpenseSubCategory[1]."Expense Category Code", ExpenseSubCategory[1].Code, WorkDate(), Amount - AmountReduction, LibraryRandom.RandInt(1));
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItemization[2], ExpenseReportLine, ExpenseSubCategory[2]."Expense Category Code", ExpenseSubCategory[2].Code, WorkDate(), AmountReduction - 1, LibraryRandom.RandInt(1));

        // [GIVEN] Enqueue expected Message text.
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(StrSubstNo(ItemizationTotalMismatchErr, Amount - 1, Amount));

        // [WHEN] Set Non-Refundable Amount in Expense Report Line.
        ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".SetValue(AmountReduction);
        ExpenseReportPage."Expense Report Subform".Itemizations.Invoke();

        // [THEN] Verify that the Itemization Total Mismatch error in rule violation.
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(ItemizationTotalMismatchErr, Amount - 1, ExpenseReportLine.Amount));
        Assert.AreEqual(
            false,
            ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".Caption(), ExpenseReportPage.Caption()));
    end;

    [Test]
    procedure RefundableMustBeTrueInExpenseReportLineWhenNonRefundableAmountIsUpdatedInExpenseReportItemization()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpenseReportLineItemization: array[2] of Record "Expense Report Line Item";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        AmountReduction: Decimal;
    begin
        // [SCENARIO 616971] Verify that the Refundable must be true in Expense Report Line when Non-Refundable Amount is updated in Expense Report Itemization.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandIntInRange(50, 90);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Sub Category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[1], ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[2], ExpenseCategory.Code, false);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, CopyStr(ExpenseReportPage."No.".Value, 1, 20));

        // [WHEN] Create Expense Report Line Itemization with Refundable and Non-Refundable Expense Sub Category.
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItemization[1], ExpenseReportLine, ExpenseSubCategory[1]."Expense Category Code", ExpenseSubCategory[1].Code, WorkDate(), Amount - AmountReduction, LibraryRandom.RandInt(1));
        asserterror LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItemization[2], ExpenseReportLine, ExpenseSubCategory[2]."Expense Category Code", ExpenseSubCategory[2].Code, WorkDate(), AmountReduction - 1, LibraryRandom.RandInt(1));

        // [THEN] Verify that the Refundable must be true in Expense Report Line when Non-Refundable Amount is updated in Expense Report Itemization.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Refundable"), Format(true));
    end;

    [Test]
    procedure StatusMustBeOpenInExpenseReportIfItemizationIsUpdated()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpenseReportLineItemization: array[2] of Record "Expense Report Line Item";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        AmountReduction: Decimal;
    begin
        // [SCENARIO 616971] Verify that the Status must be Open in Expense Report if Itemization is updated
        // when Expense Report Line Itemization is created with Refundable and Non-Refundable Expense Sub Category.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandIntInRange(50, 90);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Sub Category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[1], ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[2], ExpenseCategory.Code, false);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, CopyStr(ExpenseReportPage."No.".Value, 1, 20));

        // [GIVEN] Update "Merchant Name" in Expense Report Line.
        ExpenseReportLine.Validate("Merchant Name", CopyStr(LibraryRandom.RandText(20), 1, 100));
        ExpenseReportLine.Modify();

        // [GIVEN] Create Expense Report Line Itemization with Refundable and Non-Refundable Expense Sub Category.
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItemization[1], ExpenseReportLine, ExpenseSubCategory[1]."Expense Category Code", ExpenseSubCategory[1].Code, WorkDate(), Amount - AmountReduction, LibraryRandom.RandInt(1));
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItemization[2], ExpenseReportLine, ExpenseSubCategory[2]."Expense Category Code", ExpenseSubCategory[2].Code, WorkDate(), AmountReduction, LibraryRandom.RandInt(1));

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Update "Daily Rate" in Expense Report Line Itemization.
        asserterror ExpenseReportLineItemization[1].Validate("Daily Rate", LibraryRandom.RandDec(100, 2));

        // [THEN] Verify that the Status is Open if Itemization is updated.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));
    end;

    [Test]
    procedure MileageIsNonEditableInExpenseReportLineWhenPerDiemRuleIsApplied()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify that the Mileage is non-editable in Expense Report Line when Per Diem Rule is applied.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Rule With Condition "Per Diem".
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", Amount);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        // [WHEN] Create Expense Report Line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform"."Expense Location".SetValue(ExpenseLocation."No.");

        // [THEN] Verify that the Mileage field is non-editable in Expense Report Line when Per Diem Rule is applied.
        Assert.AreEqual(
            false,
            ExpenseReportPage."Expense Report Subform"."Mileage".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportPage."Expense Report Subform"."Mileage".Caption(), ExpenseReportPage.Caption()));

        // [THEN] Verify that Amount is not editable in Expense Report.
        Assert.AreEqual(
            false,
            ExpenseReportPage."Expense Report Subform".Amount.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportPage."Expense Report Subform".Amount.Caption(), ExpenseReportPage.Caption()));
    end;

    [Test]
    procedure MileageIsEditableInExpenseReportLineWhenMileageRuleIsApplied()
    var
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify that the Mileage is editable in Expense Report Line when Mileage Rule is applied.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Mileage, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Rule With Condition "Mileage".
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", Amount);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        // [WHEN] Create Expense Report Line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);

        // [THEN] Verify that the Mileage field is editable in Expense Report Line when Mileage Rule is applied.
        Assert.AreEqual(
            true,
            ExpenseReportPage."Expense Report Subform"."Mileage".Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportPage."Expense Report Subform"."Mileage".Caption(), ExpenseReportPage.Caption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure JustificationCanBeUpdatedInExpenseReportLineWhenCreatedFromExpenseAndBlankInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify Expense Justification can be updated in Expense Report Line When Expense Report is created from Expense and Justification is blank in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [WHEN] Update "Justification" in Expense Report Line.
        ExpenseReportLine.Validate(Justification, Format(Amount));

        // [THEN] Verify that "Justification" can be updated in Expense Report Line When Expense Report is created from Expense and Justification is blank in Expense.
        Assert.AreEqual(
            Format(Amount),
            ExpenseReportLine.Justification,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption(Justification), Format(Amount), ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseDateCanBeUpdatedInExpenseReportLineWhenCreatedFromExpenseAndBlankInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        NewExpenseDate: Date;
    begin
        // [SCENARIO 617013] Verify Expense Date can be updated in Expense Report Line When Expense Report is created from Expense and Expense Date is blank in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);
        Expense.Validate("Expense Date", 0D);
        Expense.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Generate New Expense Date.
        NewExpenseDate := WorkDate() + LibraryRandom.RandInt(5);

        // [WHEN] Update "Expense Date" in Expense Report Line.
        ExpenseReportLine.Validate("Expense Date", NewExpenseDate);

        // [THEN] Verify that "Expense Date" can be updated in Expense Report Line When Expense Report is created from Expense and Expense Date is blank in Expense.
        Assert.AreEqual(
            NewExpenseDate,
            ExpenseReportLine."Expense Date",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Date"), NewExpenseDate, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseTimeCanBeUpdatedInExpenseReportLineWhenCreatedFromExpenseAndBlankInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        NewExpenseTime: Time;
    begin
        // [SCENARIO 617013] Verify Expense Time can be updated in Expense Report Line When Expense Report is created from Expense and Expense Time is blank in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);
        Expense.Validate("Expense Time", 0T);
        Expense.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Generate New Expense Time.
        NewExpenseTime := Time + (LibraryRandom.RandInt(3600) * 1000);

        // [WHEN] Update "Expense Time" in Expense Report Line.
        ExpenseReportLine.Validate("Expense Time", NewExpenseTime);

        // [THEN] Verify that "Expense Time" can be updated in Expense Report Line When Expense Report is created from Expense and Expense Time is blank in Expense.
        Assert.AreEqual(
            NewExpenseTime,
            ExpenseReportLine."Expense Time",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Time"), NewExpenseTime, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseLocationCanBeUpdatedInExpenseReportLineWhenCreatedFromExpenseAndBlankInExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseLocation: Record "Expense Location";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify Expense Location can be updated in Expense Report Line When Expense Report is created from Expense and Expense Location is blank in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Remove any existing (demo) Expense Locations so the new one
        // cannot conflict on the same Country/Region Code, County, and City.
        ExpenseLocation.DeleteAll();

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);
        Expense.Validate("Expense Detail Required", Expense."Expense Detail Required"::"Per Diem");
        Expense.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [WHEN] Update "Expense Location" in Expense Report Line.
        ExpenseReportLine.Validate("Expense Location", ExpenseLocation."No.");

        // [THEN] Verify that "Expense Location" can be updated in Expense Report Line When Expense Report is created from Expense and Expense Location is blank in Expense.
        Assert.AreEqual(
            ExpenseLocation."No.",
            ExpenseReportLine."Expense Location",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Location"), ExpenseLocation."No.", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure MileageCanBeUpdatedInExpenseReportLineWhenCreatedFromExpenseAndBlankInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        NewMileage: Decimal;
    begin
        // [SCENARIO 617013] Verify Mileage can be updated in Expense Report Line When Expense Report is created from Expense and Mileage is blank in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense without setting Mileage (leaves it blank/zero).
        CreateExpense(Expense, true, CurrencyCode, Amount);
        Expense.Validate("Expense Detail Required", Expense."Expense Detail Required"::Mileage);
        Expense.Validate(Mileage, 0);
        Expense.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Generate New Mileage.
        NewMileage := LibraryRandom.RandDecInRange(100, 300, 2);

        // [WHEN] Update "Mileage" in Expense Report Line.
        ExpenseReportLine.Validate(Mileage, NewMileage);

        // [THEN] Verify that "Mileage" can be updated in Expense Report Line When Expense Report is created from Expense and Mileage is blank in Expense.
        Assert.AreEqual(
            NewMileage,
            ExpenseReportLine.Mileage,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption(Mileage), NewMileage, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure StartingPointCanBeUpdatedInExpenseReportLineWhenCreatedFromExpenseAndBlankInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        NewStartingPoint: Text[50];
    begin
        // [SCENARIO 617013] Verify Starting Point can be updated in Expense Report Line When Expense Report is created from Expense and Starting Point is blank in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense without setting Starting Point (leaves it blank).
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Generate New Starting Point.
        NewStartingPoint := CopyStr(LibraryRandom.RandText(50), 1, 50);

        // [WHEN] Update "Starting Point" in Expense Report Line.
        ExpenseReportLine.Validate("Starting Point", NewStartingPoint);

        // [THEN] Verify that "Starting Point" can be updated in Expense Report Line When Expense Report is created from Expense and Starting Point is blank in Expense.
        Assert.AreEqual(
            NewStartingPoint,
            ExpenseReportLine."Starting Point",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Starting Point"), NewStartingPoint, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure EndingPointCanBeUpdatedInExpenseReportLineWhenCreatedFromExpenseAndBlankInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        NewEndingPoint: Text[50];
    begin
        // [SCENARIO 617013] Verify Ending Point can be updated in Expense Report Line When Expense Report is created from Expense and Ending Point is blank in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense without setting Ending Point (leaves it blank).
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Generate New Ending Point.
        NewEndingPoint := CopyStr(LibraryRandom.RandText(50), 1, 50);

        // [WHEN] Update "Ending Point" in Expense Report Line.
        ExpenseReportLine.Validate("Ending Point", NewEndingPoint);

        // [THEN] Verify that "Ending Point" can be updated in Expense Report Line When Expense Report is created from Expense and Ending Point is blank in Expense.
        Assert.AreEqual(
            NewEndingPoint,
            ExpenseReportLine."Ending Point",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Ending Point"), NewEndingPoint, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AmountReductionCanBeUpdatedInExpenseReportLineWhenCreatedFromExpenseAndBlankInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        NewAmountReduction: Decimal;
    begin
        // [SCENARIO 617013] Verify Amount Reduction can be updated in Expense Report Line When Expense Report is created from Expense and Amount Reduction is blank in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense without setting Non-Refundable Amount (leaves it zero).
        CreateExpense(Expense, true, CurrencyCode, Amount);
        Expense.Validate("Non-Refundable Amount", 0);
        Expense.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Generate New Non-Refundable Amount.
        NewAmountReduction := LibraryRandom.RandDecInRange(10, 50, 2);

        // [WHEN] Update "Non-Refundable Amount" in Expense Report Line.
        ExpenseReportLine.Validate("Non-Refundable Amount", NewAmountReduction);

        // [THEN] Verify that "Non-Refundable Amount" can be updated in Expense Report Line When Expense Report is created from Expense and Non-Refundable Amount is blank in Expense.
        Assert.AreEqual(
            NewAmountReduction,
            ExpenseReportLine."Non-Refundable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Non-Refundable Amount"), NewAmountReduction, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ExpenseReportLineItemsEditableModalPageHandler')]
    procedure ExpenseReportItemizationPageMustBeEditableWhenExpenseReportIsCreatedFromExpenseAndHasRuleViolation()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseCategory: Record "Expense Category";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify that the Expense Report Itemization Page must be editable when Expense Report is created from Expense and has rule violation.
        Initialize();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, '', '', CurrencyCode, Amount, WorkDate(), '',
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::Always, '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseCategory.Code, Expense."Expense Subcategory", WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [WHEN] Show Itemization from Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        ExpenseReportLine.ShowItemization();

        // [THEN] Verify that Expense Report Itemization Page must be editable.
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ExpenseReportLinePerDiemEditableModalPageHandler')]
    procedure ExpenseReportPerDiemPageMustBeEditableWhenExpenseReportIsCreatedFromExpenseAndHasRuleViolation()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 617013] Verify that the Expense Report Per Diem Page must be editable when Expense Report is created from Expense and has rule violation.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(), ExpensePaymentMethod.Code,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::Always, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", false, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [WHEN] Invoke Per Diem from Expense Report Line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that Expense Report Per Diem Page must be editable.
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ExpenseReportLineParticipantsEditableModalPageHandler')]
    procedure ExpenseReportParticipantPageMustBeEditableWhenExpenseReportIsCreatedFromExpenseAndRuleViolation()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify that the Expense Report Participant Page must be editable when Expense Report is created from Expense and Rule Violation.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, '', '', CurrencyCode, Amount, WorkDate(), '',
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::Always, '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [WHEN] Show Participants from Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        ExpenseReportLine.ShowParticipants();

        // [THEN] Verify that Expense Report Participant Page must be editable.
    end;

    [Test]
    procedure AmountMustBeEditableInExpenseReport()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616954] Verify that Amount must be editable in Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [THEN] Verify that Amount is editable in Expense Report.
        Assert.AreEqual(
            true,
            ExpenseReportPage."Expense Report Subform".Amount.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportPage."Expense Report Subform".Amount.Caption(), ExpenseReportPage.Caption()));
    end;

    [Test]
    procedure ExpenseLocationMustNotBeEditableWhenExpenseDetailIsItemized()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 616941] Verify that Expense Location must not be editable when Expense Detail is Itemized.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [THEN] Verify that "Expense Location" must not be editable in Expense Report.
        Assert.AreEqual(
            false,
            ExpenseReportPage."Expense Report Subform"."Expense Location".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportPage."Expense Report Subform"."Expense Location".Caption(), ExpenseReportPage.Caption()));
    end;

    [Test]
    procedure ExpenseLocationMustNotBeEditableWhenExpenseDetailIsMileage()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 616941] Verify that Expense Location must not be editable when Expense Detail is Mileage.
        Initialize();

        // [GIVEN] Update Default Unit of Measure in Expense Agent Setup.
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Mileage, ExpensePaymentMethod.Code);

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [THEN] Verify that "Expense Location" must not be editable in Expense Report.
        Assert.AreEqual(
            false,
            ExpenseReportPage."Expense Report Subform"."Expense Location".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportPage."Expense Report Subform"."Expense Location".Caption(), ExpenseReportPage.Caption()));

        // [THEN] Verify that Amount is not editable in Expense Report.
        Assert.AreEqual(
            false,
            ExpenseReportPage."Expense Report Subform".Amount.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportPage."Expense Report Subform".Amount.Caption(), ExpenseReportPage.Caption()));
    end;

    [Test]
    procedure ExpenseLocationMustNotBeEditableWhenExpenseDetailIsParticipant()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 616941] Verify that Expense Location must not be editable when Expense Detail is Participant.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Participants, ExpensePaymentMethod.Code);

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [THEN] Verify that "Expense Location" must not be editable in Expense Report.
        Assert.AreEqual(
            false,
            ExpenseReportPage."Expense Report Subform"."Expense Location".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportPage."Expense Report Subform"."Expense Location".Caption(), ExpenseReportPage.Caption()));

        // [THEN] Verify that Amount is editable in Expense Report.
        Assert.AreEqual(
            true,
            ExpenseReportPage."Expense Report Subform".Amount.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportPage."Expense Report Subform".Amount.Caption(), ExpenseReportPage.Caption()));
    end;

    [Test]
    procedure ExpenseLocationMustBeEditableWhenExpenseDetailIsPerDiem()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 616941] Verify that Expense Location must be editable when Expense Detail is Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [THEN] Verify that "Expense Location" must be editable in Expense Report.
        Assert.AreEqual(
            true,
            ExpenseReportPage."Expense Report Subform"."Expense Location".Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportPage."Expense Report Subform"."Expense Location".Caption(), ExpenseReportPage.Caption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseLocationMustBeUpdatedWhenExpenseCategoryIsChangedInExpenseReportLine()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        Amount: Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 616941] Verify that Expense Location must be updated when Expense Category is changed in Expense Report Line.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

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
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, Amount);

        // [THEN] Verify that Per Diem records exist for the Expense Report Line.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 1);

        // [GIVEN] Reopen Expense Report.
        ExpenseReportHeader.SetRange("No.", ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualReopen(ExpenseReportHeader);

        // [WHEN] Update Expense Category in Expense Report Line.
        ExpenseReportLine.Validate("Expense Category", '');

        // [THEN] Verify that "Expense Location" is updated in Expense Report Line.
        Assert.AreEqual(
            '',
            ExpenseReportLine."Expense Location",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Location"), '', ExpenseReportLine.TableCaption()));

        // [THEN] Verify that no Per Diem records exist for the Expense Report Line.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 0);
    end;

    [Test]
    procedure ExpenseReportLinePerDiemIsDeletedWhenExpenseLocationIsChangedForPerDiem()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        EmptyGuid: Guid;
        Amount: Decimal;
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 616941] Verify that Expense Report Line Per Diem is deleted when Expense Location is changed for Per Diem.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        UpdatePerDiemInExpenseAgentSetup();

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
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, Amount);

        // [THEN] Verify that Rule Id is updated in Expense Report.
        Assert.AreEqual(
            ExpenseRuleHeader.SystemId,
            ExpenseReportLine."Applied Rule Id",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Applied Rule Id"), ExpenseRuleHeader.SystemId, ExpenseReportLine.TableCaption()));

        // [THEN] Verify that Per Diem records exist for the Expense Report Line.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 1);

        // [GIVEN] Reopen Expense Report.
        ExpenseReportHeader.SetRange("No.", ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualReopen(ExpenseReportHeader);

        // [WHEN] Update Expense Location in Expense Report Line.
        ExpenseReportLine.Validate("Expense Location", '');

        // [THEN] Verify that no Per Diem records exist for the Expense Report Line.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 0);

        // [THEN] Verify that Rule Id is cleared in Expense Report.
        Assert.AreEqual(
            EmptyGuid,
            ExpenseReportLine."Applied Rule Id",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Applied Rule Id"), EmptyGuid, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure ExpenseReportLineCanBeDeletedWhenExpensePerDiemIsExists()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        CurrencyCode: Code[10];
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 616956] Verify that Expense Report Line can be deleted when Expense Per Diem is exists.
        Initialize();

        // [GIVEN] Setup Expense Source Code.
        LibraryExpense.InitializeExpenseSourceCode();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(WorkDate(), 235900T);

        // [GIVEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, 0);

        // [WHEN] Reopen Expense Report.
        ExpenseReportHeader.SetFilter("No.", ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualReopen(ExpenseReportHeader);

        // [THEN] Verify that the new Per Diem entry are created in Expense Report Per Diem Page.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 1);

        // [WHEN] Delete Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseReportLine.Delete(true);

        // [THEN] Verify that the Expense Report Line can be deleted when Expense Per Diem is exists.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 0);

        // [THEN] Verify that the Expense Report Line is deleted.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLine, 0);
    end;

    [Test]
    [HandlerFunctions('AddExpenseItemizationsWithSubCategoryHandler')]
    procedure ExpenseReportLineCanBeDeletedWhenExpenseItemizationsExist()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpenseReportLineItemization: Record "Expense Report Line Item";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        AmountReduction: Decimal;
    begin
        // [SCENARIO 616956] Verify that Expense Report Line can be deleted when Expense Itemizations exist.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandIntInRange(50, 90);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Sub Category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[1], ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[2], ExpenseCategory.Code, false);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [GIVEN] Enqueue Expense Sub Category Code, Quantity and Amount for Expense Itemization.
        LibraryVariableStorage.Enqueue(ExpenseSubCategory[1].Code);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(Amount - AmountReduction);

        LibraryVariableStorage.Enqueue(ExpenseSubCategory[2].Code);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(AmountReduction);

        // [WHEN] Add Itemization from Expense Itemizations Page.
        ExpenseReportHeader.Get(ExpenseReportPage."No.".Value());
        ExpenseReportPage."Expense Report Subform".Itemizations.Invoke();
        ExpenseReportPage.Close();

        // [THEN] Verify that the new Itemizations are created in Expense Report Line Itemization Page.
        ExpenseReportLineItemization.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLineItemization, 2);

        // [WHEN] Delete Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseReportLine.Delete(true);

        // [THEN] Verify that the Expense Report Line can be deleted when Expense Itemizations exist.
        ExpenseReportLineItemization.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLineItemization, 0);

        // [THEN] Verify that the Expense Report Line is deleted.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLine, 0);
    end;

    [Test]
    procedure DescriptionMustBeBlankWhenExpenseCategoryIsRemovedInExpenseReportLine()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 616949] Verify that the Description is blank when Expense Category is removed.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [THEN] Verify that Description is populated in Expense Report Line.
        ExpenseReportPage."Expense Report Subform".Description.AssertEquals(ExpenseCategory."Posting Description");

        // [WHEN] Remove Expense Category in Expense Report Line.
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue('');

        // [THEN] Verify that Description is blank in Expense Report Line.
        ExpenseReportPage."Expense Report Subform".Description.AssertEquals('');
    end;

    [Test]
    procedure AmountReductionCannotBeNegativeInExpenseReportLine()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 616953] Verify that the Amount Reduction cannot be negative in Expense Report Line.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [WHEN] Set Negative Non-Refundable Amount in Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, CopyStr(ExpenseReportPage."No.".Value(), 1, 20));
        asserterror ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".SetValue(-Amount);

        // [THEN] Verify that the error is thrown for negative Non-Refundable Amount.
        Assert.ExpectedError(StrSubstNo(NonRefundableAmountCannotBeNegativeErr, ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".Caption(), ExpenseReportLine."Document No.", ExpenseReportLine."Line No."));
    end;

    [Test]
    procedure DefaultMileageUOMIsRequiredWhenExpenseReportIsCreatedForMileage()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO 616955] Verify that Default Mileage UOM is required when Expense Report is created for Mileage.
        Initialize();

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Validate("Default Mileage UOM", '');
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Mileage, ExpensePaymentMethod.Code);

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        asserterror ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);

        // [THEN] Verify that Default Mileage UOM is required when Expense is created for Mileage.
        Assert.ExpectedTestFieldError(ExpenseAgentSetup.FieldCaption("Default Mileage UOM"), '');
    end;

    [Test]
    procedure UnitOfMeasureMustBeClearedWhenExpenseCategoryIsCleared()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        UnitOfMeasure: Record "Unit of Measure";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO 616955] Verify that Unit of Measure must be cleared when Expense Category is cleared.
        Initialize();

        // [GIVEN] Create Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
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

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);

        // [THEN] Verify that the Unit of Measure is set to Default Mileage UOM in Expense Report.
        FindExpenseReportLine(ExpenseReportLine, CopyStr(ExpenseReportPage."No.".Value(), 1, 20));
        Assert.AreEqual(
            UnitOfMeasure.Code,
            ExpenseReportLine."Unit of Measure Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Unit of Measure Code"), UnitOfMeasure.Code, ExpenseReportLine.TableCaption()));

        // [WHEN] Clear Expense Category in Expense Report.
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue('');

        // [THEN] Verify that the Unit of Measure is cleared in Expense Report.
        FindExpenseReportLine(ExpenseReportLine, CopyStr(ExpenseReportPage."No.".Value(), 1, 20));
        Assert.AreEqual(
            '',
            ExpenseReportLine."Unit of Measure Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Unit of Measure Code"), '', ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure MerchantNameAndExtDocNoMustFlowFromExpenseToExpenseReport()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        MerchantName: Text[100];
        ExpenseExtDocNo: Text[30];
        OriginalMileage: Decimal;
    begin
        // [SCENARIO 616955] Verify that Merchant Name and Ext. Doc. No. must flow from Expense to Expense Report.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);
        OriginalMileage := LibraryRandom.RandDecInRange(50, 500, 2);
        MerchantName := CopyStr(LibraryRandom.RandText(20), 1, 100);
        ExpenseExtDocNo := CopyStr(LibraryRandom.RandText(20), 1, 30);

        // [GIVEN] Create Expense with Mileage.
        CreateExpense(Expense, true, CurrencyCode, Amount);
        Expense.Validate("Expense Detail Required", Expense."Expense Detail Required"::Mileage);
        Expense.Validate("Merchant Name", MerchantName);
        Expense.Validate("Expense Ext. Doc. No.", ExpenseExtDocNo);
        Expense.Validate(Mileage, OriginalMileage);
        Expense.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [THEN] Verify that Merchant Name and Ext. Doc. No. flow from Expense to Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        Assert.AreEqual(
            MerchantName,
            ExpenseReportLine."Merchant Name",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Merchant Name"), MerchantName, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            UpperCase(ExpenseExtDocNo),
            ExpenseReportLine."Expense Ext. Doc. No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Ext. Doc. No."), UpperCase(ExpenseExtDocNo), ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure MerchantNameCanBeUpdatedInExpenseReportLineWhenCreatedFromExpenseAndBlankInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616955] Verify Expense Merchant Name can be updated in Expense Report Line When Expense Report is created from Expense and Merchant Name is blank in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [WHEN] Update "Merchant Name" in Expense Report Line.
        ExpenseReportLine.Validate("Merchant Name", Format(Amount));

        // [THEN] Verify that "Merchant Name" can be updated in Expense Report Line When Expense Report is created from Expense and Merchant Name is blank in Expense.
        Assert.AreEqual(
            Format(Amount),
            ExpenseReportLine."Merchant Name",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Merchant Name"), Format(Amount), ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseExternalDocNoCanBeUpdatedInExpenseReportLineWhenCreatedFromExpenseAndBlankInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616955] Verify Expense External Document No can be updated in Expense Report Line When Expense Report is created from Expense and External Document No is blank in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        CreateAndAttachExpenseReport(ExpenseReportHeader, Expense);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [WHEN] Update "Expense Ext. Doc. No." in Expense Report Line.
        ExpenseReportLine.Validate("Expense Ext. Doc. No.", Format(Amount));

        // [THEN] Verify that "Expense Ext. Doc. No." can be updated in Expense Report Line When Expense Report is created from Expense and Expense Ext. Doc. No. is blank in Expense.
        Assert.AreEqual(
            Format(Amount),
            ExpenseReportLine."Expense Ext. Doc. No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Ext. Doc. No."), Format(Amount), ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure EmployeeMustBeLinkedToAnExpenseUserToCreateAnExpenseReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617988] Verify that Employee must be linked to an Expense User to create an Expense Report.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("Employee No.", '');
        ExpenseUser.Modify();

        // [WHEN] Create Expense Report.
        asserterror LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [THEN] Verify that the error is thrown for Expense User not linked to an Employee.
        Assert.ExpectedError(StrSubstNo(ExpenseUserMustBeLinkedToAnEmployeeErr, ExpenseUser."No."));
    end;

    [Test]
    [HandlerFunctions('ExpenseReportDetailsRequestPageHandler')]
    procedure VerifyDataOfExpenseReportDetail()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: array[3] of Record "Expense Report Line";
        CurrencyCode: Code[10];
        JobNo: Code[20];
        Amount: array[3] of Decimal;
        LineDescription: Text[100];
        AdditionalInformation: Text[100];
        LineJustification: Text[100];
        i: Integer;
    begin
        // [SCENARIO 580731] Verify the data of "Expense Report Details".
        Initialize();

        // [GIVEN] Create Expense Report.
        CreateExpenseReport(ExpenseUser, ExpenseReportHeader, CurrencyCode);

        // [GIVEN] Create three Expense Report Lines.
        CreateExpenseReportLineWithMultipleLines(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Amount, LineDescription, AdditionalInformation, LineJustification, true, JobNo, 3);

        // [GIVEN] Save the transaction.
        Commit();

        // [WHEN] Run the report.
        RunExpenseReportDetail(ExpenseReportHeader);

        // [THEN] Verify the data of "Expense Report Details".
        for i := 1 to 3 do
            VerifyExpenseReportHeaderAndLineValuesInDataset(ExpenseReportHeader, ExpenseReportLine[i]);
    end;

    [Test]
    procedure VerifyDataOfExpenseReportCoverPage()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        CurrencyCode: Code[10];
        EmployeePaidRefundableAmount: Decimal;
        EmployeePaidNonRefundableAmount: Decimal;
        CompanyPaidRefundableAmount: Decimal;
        TotalPaidByCompanyLCY: Decimal;
        TotalNonRefundableAmountLCY: Decimal;
        TotalRefundableAmountLCY: Decimal;
    begin
        // [SCENARIO 580731] Verify the data of "Expense Report Cover Page".
        Initialize();

        // [GIVEN] Generate Random Amount.
        EmployeePaidRefundableAmount := LibraryRandom.RandIntInRange(100, 200);
        EmployeePaidNonRefundableAmount := LibraryRandom.RandIntInRange(50, 99);
        CompanyPaidRefundableAmount := LibraryRandom.RandIntInRange(30, 80);

        // [GIVEN] Create Expense Report.
        CreateExpenseReport(ExpenseUser, ExpenseReportHeader, CurrencyCode);

        // [GIVEN] Create Employee Paid line with Refundable Amount.
        CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, EmployeePaidRefundableAmount, true, "Expense Reimbursement Type"::"Employee Paid");

        // [GIVEN] Create Employee Paid line with Non-Refundable Amount.
        CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, EmployeePaidNonRefundableAmount, false, "Expense Reimbursement Type"::"Employee Paid");

        // [GIVEN] Create Company Paid line with Refundable Amount.
        CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, CompanyPaidRefundableAmount, true, "Expense Reimbursement Type"::"Company Paid");

        // [GIVEN] Calculate Expected Total.
        CalculateTotalsFoExpenseReportCoverPageReport(ExpenseReportHeader."No.", TotalPaidByCompanyLCY, TotalNonRefundableAmountLCY, TotalRefundableAmountLCY);

        // [WHEN] Run the Cover Page Report.
        ExpenseReportHeader.SetRange("No.", ExpenseReportHeader."No.");
        LibraryReportDataset.RunReportAndLoad(Report::"Expense Report Cover Page", ExpenseReportHeader, '');

        // [THEN] Verify the data of "Expense Report Cover Page".
        VerifyExpenseReportCoverPageValuesInDataset(ExpenseReportHeader, TotalPaidByCompanyLCY, TotalNonRefundableAmountLCY, TotalRefundableAmountLCY);
    end;

    [Test]
    [HandlerFunctions('PerDiemExpenseReportWithoutRuleModalPageErrorHandler,SentNotificationHandler')]
    procedure MissingExpenseReportLocationNotificationOnExpenseReportLinePerDiem()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621716] Verify that Missing Expense Report Location Notification is triggered on Expense Report Line Per Diem.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::"Per Diem");

        // [GIVEN] Create Expense Report Header.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', LibraryRandom.RandInt(100));

        // [WHEN] Open Expense Report Page and invoke Per Diem action.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that Missing Expense Report Location Notification is triggered.
        VerifyMissingExpenseReportLocationNotification(ExpenseReportHeader."No.", ExpenseReportLine."Line No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure VerifyDataOfExpenseReportSummaryPage()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        CurrencyCode: Code[10];
        MileageAmount: Decimal;
        PerDiemAmount: Decimal;
        OtherExpenseAmount: Decimal;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 580731] Verify the data of "Expense Report Summary Page".
        Initialize();

        // [GIVEN] Generate Random Amount.
        MileageAmount := LibraryRandom.RandIntInRange(100, 200);
        PerDiemAmount := LibraryRandom.RandIntInRange(50, 99);
        OtherExpenseAmount := LibraryRandom.RandIntInRange(30, 80);

        // [GIVEN] Create Expense Report.
        CreateExpenseReport(ExpenseUser, ExpenseReportHeader, CurrencyCode);

        // [GIVEN] Create Line with Mileage.
        CreateExpenseReportLineWithMileage(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, MileageAmount, true, "Expense Reimbursement Type"::"Employee Paid");

        // [GIVEN] Create Line with Per Diem.
        CreateExpenseReportLineWithPerDiem(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, PerDiemAmount, false, "Expense Reimbursement Type"::"Employee Paid");

        // [GIVEN] Create a normal expense line.
        CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, OtherExpenseAmount, true, "Expense Reimbursement Type"::"Company Paid");

        // [WHEN] Run the Summary Page Report.
        ExpenseReportHeader.SetRange("No.", ExpenseReportHeader."No.");
        LibraryReportDataset.RunReportAndLoad(Report::"Expense Report Summary Page", ExpenseReportHeader, '');

        // [THEN] Verify the data of "Expense Report Summary Page".
        VerifyExpenseReportSummaryPageValuesInDataset(ExpenseReportHeader, MileageAmount, PerDiemAmount, OtherExpenseAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Report Test");
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        // The tests release reports but do not approve them; by default keep approval checks and the agent disabled.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        LibraryExpense.UpdateEnableAgentInAgentSetup(false);
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Report Test");
    end;

    local procedure CreateExpense(var Expense: Record Expense; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        ExpenseUser: Record "Expense User";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateExpense(Expense, ExpenseUser, Refundable, CurrencyCode, Amount);
    end;

    local procedure CreateExpense(var Expense: Record Expense; ExpenseUser: Record "Expense User"; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, Refundable);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', Refundable, CurrencyCode, Amount);
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

    local procedure FindExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; Expense: Record Expense)
    begin
        ExpenseReportLine.SetRange("Expense No.", Expense."No.");
        ExpenseReportLine.FindFirst();
    end;

    local procedure FindExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; ExpenseReportNo: Code[20])
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportNo);
        ExpenseReportLine.FindFirst();
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
        PaymentMethodCode: Code[10];
        ExpenseDetailRequired: Enum "Expense Detail Needed";
        JustificationRequired: Enum "Expense Justification";
        UnitOfMeasureCode: Code[10];
        ConditionType: Enum "Expense Rule Condition Type";
        Refundable: Boolean;
        Value: Decimal);
    var
        ExpenseUser: Record "Expense User";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        CreateExpenseWithRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, CountryRegionCode, City, CurrencyCode, Amount, EffectiveDate,
            PaymentMethodCode, ExpenseDetailRequired, JustificationRequired, UnitOfMeasureCode, ConditionType, Refundable, Value);
    end;

    local procedure CreateExpenseWithRule(
        var Expense: Record Expense;
        var ExpenseUser: Record "Expense User";
        var ExpenseRuleHeader: Record "Expense Rule Header";
        var ExpenseRuleCondition: Record "Expense Rule Condition";
        CountryRegionCode: Code[10];
        City: Text[30];
        CurrencyCode: Code[10];
        Amount: Decimal;
        EffectiveDate: Date;
        PaymentMethodCode: Code[10];
        ExpenseDetailRequired: Enum "Expense Detail Needed";
        JustificationRequired: Enum "Expense Justification";
        UnitOfMeasureCode: Code[10];
        ConditionType: Enum "Expense Rule Condition Type";
        Refundable: Boolean;
        Value: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseDetailRequired, PaymentMethodCode);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, Refundable);

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

    local procedure CreateAndReleaseExpenseReportWithPerDiemRule(
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
        ExpenseReportHeader.PerformManualRelease();
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

    local procedure CreateExpenseReportLineParticipant(var ExpenseReportLineParticip: Record "Expense Report Line Particip."; ExpenseReportLine: Record "Expense Report Line")
    var
        RecordRef: RecordRef;
    begin
        ExpenseReportLineParticip.Init();
        ExpenseReportLineParticip.Validate("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticip.Validate("Expense Report Line No.", ExpenseReportLine."Line No.");
        RecordRef.GetTable(ExpenseReportLineParticip);
        ExpenseReportLineParticip.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseReportLineParticip.FieldNo("Line No.")));
        ExpenseReportLineParticip.Insert(true);
    end;

    local procedure CreateDocumentAttachmentForExpenseReportLine(var DocumentAttachment: Record "Document Attachment"; ExpenseReportLine: Record "Expense Report Line"; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStream: OutStream;
    begin
        RecRef.GetTable(ExpenseReportLine);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(FileName);

        Clear(DocumentAttachment);
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
    end;

    local procedure CreateDocumentAttachmentForExpense(var DocumentAttachment: Record "Document Attachment"; Expense: Record Expense; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStream: OutStream;
    begin
        RecRef.GetTable(Expense);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(FileName);

        Clear(DocumentAttachment);
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
    end;

    local procedure CreateExpenseReportLineComment(ExpenseReportLine: Record "Expense Report Line"; CommentText: Text[80])
    var
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
        RecordRef: RecordRef;
    begin
        ExpenseReportCommentLine.Init();
        ExpenseReportCommentLine."Document Type" := ExpenseReportCommentLine."Document Type"::"Expense Report";
        ExpenseReportCommentLine."No." := ExpenseReportLine."Document No.";
        ExpenseReportCommentLine."Document Line No." := ExpenseReportLine."Line No.";
        RecordRef.GetTable(ExpenseReportCommentLine);
        ExpenseReportCommentLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseReportCommentLine.FieldNo("Line No.")));
        ExpenseReportCommentLine.Date := WorkDate();
        ExpenseReportCommentLine.Comment := CommentText;
        ExpenseReportCommentLine.Insert();
    end;

    local procedure CreateExpenseReportLine(
        var ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUserNo: Code[20];
        CurrencyCode: Code[10];
        Amount: Decimal;
        MerchantName: Text[100];
        LineDescription: Text[100];
        AdditionalInformation: Text[100];
        LineJustification: Text[100];
        IsBillable: Boolean;
        var JobNo: Code[20])
    var
        ExpenseCategory: Record "Expense Category";
        PaymentMethod: Record "Expense Payment Method";
        Job: Record Job;
    begin
        LibraryExpense.FindExpensePaymentMethod(PaymentMethod, PaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ", PaymentMethod.Code);

        if JobNo = '' then begin
            LibraryJob.CreateJob(Job);
            Job.Validate("Currency Code", CurrencyCode);
            Job.Modify(true);
            JobNo := Job."No.";
        end;

        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUserNo, ExpenseCategory.Code, PaymentMethod.Code, true, CurrencyCode, Amount);
        ExpenseReportLine.Validate("Expense Date", WorkDate());
        ExpenseReportLine.Validate("Merchant Name", MerchantName);
        ExpenseReportLine.Validate("Job No.", JobNo);
        ExpenseReportLine.Validate(Billable, IsBillable);
        ExpenseReportLine.Validate(Description, LineDescription);
        ExpenseReportLine.Validate("Additional Information", AdditionalInformation);
        ExpenseReportLine.Validate(Justification, LineJustification);
        ExpenseReportLine.Modify(true);
    end;

    local procedure CreateExpenseReportLineWithMileage(ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserCode: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; Refundable: Boolean; ReimbursementType: Enum "Expense Reimbursement Type")
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        PaymentMethod: Record "Expense Payment Method";
    begin
        LibraryExpense.FindExpensePaymentMethod(PaymentMethod, ReimbursementType);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ReimbursementType, ExpenseCategory."Expense Detail Required"::Mileage, PaymentMethod.Code);
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUserCode, ExpenseCategory.Code, PaymentMethod.Code, true, CurrencyCode, Amount);
        ExpenseReportLine.Validate("Expense Date", WorkDate());
        ExpenseReportLine.Validate(Refundable, Refundable);
        ExpenseReportLine.Validate(Mileage, LibraryRandom.RandDecInRange(50, 500, 2));
        ExpenseReportLine.Modify(true);
    end;

    local procedure CreateExpenseReportLineWithPerDiem(ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserCode: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; Refundable: Boolean; ReimbursementType: Enum "Expense Reimbursement Type")
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        PaymentMethod: Record "Expense Payment Method";
        ExpenseLocation: Record "Expense Location";
        PostCode: Record "Post Code";
    begin
        LibraryExpense.FindExpensePaymentMethod(PaymentMethod, ReimbursementType);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ReimbursementType, ExpenseCategory."Expense Detail Required"::"Per Diem", PaymentMethod.Code);

        LibraryERM.CreatePostCode(PostCode);
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUserCode, ExpenseCategory.Code, PaymentMethod.Code, true, CurrencyCode, Amount);
        ExpenseReportLine.Validate("Expense Date", WorkDate());
        ExpenseReportLine.Validate(Refundable, Refundable);
        ExpenseReportLine.Validate("Expense Location", ExpenseLocation."No.");
        ExpenseReportLine.Validate("Starting Date and Time", CreateDateTime(WorkDate(), 080000T));
        ExpenseReportLine.Validate("Ending Date and Time", CreateDateTime(WorkDate(), 180000T));
        ExpenseReportLine.Modify(true);
    end;

    local procedure CreateExpenseReport(ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; Refundable: Boolean; ReimbursementType: Enum "Expense Reimbursement Type")
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        PaymentMethod: Record "Expense Payment Method";
    begin
        LibraryExpense.FindExpensePaymentMethod(PaymentMethod, ReimbursementType);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ReimbursementType, ExpenseCategory."Expense Detail Required"::" ", PaymentMethod.Code);
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUserNo, ExpenseCategory.Code, PaymentMethod.Code, true, CurrencyCode, Amount);
        ExpenseReportLine.Validate("Expense Date", WorkDate());
        ExpenseReportLine.Validate(Refundable, Refundable);
        ExpenseReportLine.Modify(true);
    end;

    local procedure CalculateTotalsFoExpenseReportCoverPageReport(DocumentNo: Code[20]; var TotalPaidByCompanyLCY: Decimal; var TotalNonRefundableAmountLCY: Decimal; var TotalRefundableAmountLCY: Decimal)
    var
        ExpenseReportLine: Record "Expense Report Line";
        TotalAmountReductionLCY: Decimal;
    begin
        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", DocumentNo);
        ExpenseReportLine.SetRange(Refundable, false);
        ExpenseReportLine.CalcSums("Amount (LCY)");
        TotalNonRefundableAmountLCY := ExpenseReportLine."Amount (LCY)";

        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", DocumentNo);
        ExpenseReportLine.SetFilter("Reimbursement Type", '<>%1', ExpenseReportLine."Reimbursement Type"::"Employee Paid");
        ExpenseReportLine.CalcSums("Amount (LCY)");
        TotalPaidByCompanyLCY := ExpenseReportLine."Amount (LCY)";

        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", DocumentNo);
        ExpenseReportLine.SetRange(Refundable, true);
        ExpenseReportLine.CalcSums("Amount (LCY)");
        TotalRefundableAmountLCY := ExpenseReportLine."Amount (LCY)";

        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", DocumentNo);
        ExpenseReportLine.SetRange(Refundable, true);
        ExpenseReportLine.CalcSums("Non-Refundable Amount (LCY)");
        TotalAmountReductionLCY := ExpenseReportLine."Non-Refundable Amount (LCY)";

        TotalRefundableAmountLCY := TotalRefundableAmountLCY - TotalAmountReductionLCY;
    end;

    local procedure CreateExpenseReportLineWithMultipleLines(
        var ExpenseReportLine: array[3] of Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUserNo: Code[20];
        CurrencyCode: Code[10];
        var Amount: array[3] of Decimal;
        LineDescription: Text[100];
        AdditionalInformation: Text[100];
        LineJustification: Text[100];
        Refundable: Boolean;
        var JobNo: Code[20];
        NumberOfLines: Integer)
    var
        i: Integer;
        MerchantName: Text[100];
    begin
        for i := 1 to NumberOfLines do begin
            Amount[i] := LibraryRandom.RandIntInRange(100, 200);
            MerchantName := CopyStr(LibraryRandom.RandText(20), 1, 100);
            CreateExpenseReportLine(ExpenseReportLine[i], ExpenseReportHeader, ExpenseUserNo, CurrencyCode, Amount[i], MerchantName, LineDescription, AdditionalInformation, LineJustification, Refundable, JobNo);
        end;
    end;

    local procedure VerifyExpenseReportHeaderAndLineValuesInDataset(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line")
    begin
        LibraryReportDataset.AssertElementWithValueExists(NoLbl, ExpenseReportHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(ExpenseUserNoLbl, ExpenseReportHeader."Expense User No.");
        LibraryReportDataset.AssertElementWithValueExists(ExpenseUserNameLbl, ExpenseReportHeader."Expense User Name");
        LibraryReportDataset.AssertElementWithValueExists(StatusLbl, Format(ExpenseReportHeader.Status));
        LibraryReportDataset.AssertElementWithValueExists(ExpenseCategoryLbl, ExpenseReportLine."Expense Category");
        LibraryReportDataset.AssertElementWithValueExists(MerchantLbl, ExpenseReportLine."Merchant Name");
        LibraryReportDataset.AssertElementWithValueExists(PaymentMethodLbl, ExpenseReportLine."Payment Method Code");
        LibraryReportDataset.AssertElementWithValueExists(AmountLbl, ExpenseReportLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists(CurrencyLbl, ExpenseReportLine."Expense Currency Code");
        LibraryReportDataset.AssertElementWithValueExists(AmountLCYLbl, ExpenseReportLine."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(ReimbursableAmountLCYLbl, ExpenseReportLine."Reimbursable Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(ProjectNoLbl, ExpenseReportLine."Job No.");
        LibraryReportDataset.AssertElementWithValueExists(BillableLbl, ExpenseReportLine.Billable);
    end;

    local procedure VerifyDateColumnValueInCurrentRow(ElementName: Text; ExpectedDate: Date)
    var
        ActualValue: Variant;
        ActualDate: Date;
        DateColumnMismatchErr: Label 'Date column %1 mismatch.', Comment = '%1 = report dataset element name';
    begin
        // Compare report emitted Date strings semantically (not by string formatting)
        LibraryReportDataset.GetElementValueInCurrentRow(ElementName, ActualValue);
        Evaluate(ActualDate, Format(ActualValue));
        Assert.AreEqual(ExpectedDate, ActualDate, StrSubstNo(DateColumnMismatchErr, ElementName));
    end;

    local procedure VerifyExpenseReportCoverPageValuesInDataset(
        ExpenseReportHeader: Record "Expense Report Header";
        TotalPaidByCompanyLCY: Decimal;
        TotalNonRefundableAmountLCY: Decimal;
        TotalRefundableAmountLCY: Decimal)
    var
        CompanyInformation: Record "Company Information";
        FormatAddress: Codeunit "Format Address";
        CompanyAddress: array[8] of Text[100];
    begin
        CompanyInformation.Get();
        FormatAddress.Company(CompanyAddress, CompanyInformation);
        ExpenseReportHeader.CalcFields("Amount (LCY)", "Reimbursable Amount (LCY)");

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverReportTitleLbl, ExpenseReportTitleLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverCompanyAddress1Lbl, CompanyAddress[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverCompanyAddress2Lbl, CompanyAddress[2]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverCompanyAddress3Lbl, CompanyAddress[3]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverCompanyAddress4Lbl, CompanyAddress[4]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverCompanyAddress5Lbl, CompanyAddress[5]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverCompanyAddress6Lbl, CompanyAddress[6]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverCompanyAddress7Lbl, CompanyAddress[7]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverCompanyAddress8Lbl, CompanyAddress[8]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverExpenseReportNoLbl, ExpenseReportHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverExpenseUserNameLbl, ExpenseReportHeader."Expense User Name");
        VerifyDateColumnValueInCurrentRow(CoverExpenseReportDateLbl, ExpenseReportHeader."Expense Report Date");
        VerifyDateColumnValueInCurrentRow(CoverPostingDateLbl, ExpenseReportHeader."Posting Date");
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverDescriptionLbl, ExpenseReportHeader.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverAntiCorruptionAttestationLbl, ExpenseReportHeader."Anti-Corruption Attestation");
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverAntiCorruptionDescriptionLbl, ExpenseReportHeader."Anti-Corruption Description");
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverTotalAmountLCYLbl, ExpenseReportHeader."Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverTotalReimbursableAmountLCYLbl, ExpenseReportHeader."Reimbursable Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverTotalPaidByCompanyLCYLbl, TotalPaidByCompanyLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverTotalNonRefundableAmountLCYLbl, TotalNonRefundableAmountLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverTotalRefundableAmountLCYLbl, TotalRefundableAmountLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverCurrencyCodeLbl, ExpenseReportHeader."Reimbursement Currency Code");
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverSubmittedByLbl, ExpenseReportHeader."Expense User Name");
        LibraryReportDataset.AssertCurrentRowValueEquals(CoverApprovedByLbl, ExpenseReportHeader."Approver Expense User ID");
    end;

    local procedure VerifyExpenseReportSummaryPageValuesInDataset(ExpenseReportHeader: Record "Expense Report Header"; MileageAmount: Decimal; PerDiemAmount: Decimal; OtherExpenseAmount: Decimal)
    var
        CompanyInformation: Record "Company Information";
        ExpenseUser: Record "Expense User";
        FormatAddress: Codeunit "Format Address";
        CompanyAddress: array[8] of Text[100];
    begin
        CompanyInformation.Get();
        FormatAddress.Company(CompanyAddress, CompanyInformation);
        ExpenseReportHeader.CalcFields("Amount (LCY)", "Reimbursable Amount (LCY)");
        ExpenseUser.Get(ExpenseReportHeader."Expense User No.");

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ExpenseReportNoLbl, ExpenseReportHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(CompanyAddress1Lbl, CompanyAddress[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CompanyAddress2Lbl, CompanyAddress[2]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CompanyAddress3Lbl, CompanyAddress[3]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CompanyAddress4Lbl, CompanyAddress[4]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CompanyAddress5Lbl, CompanyAddress[5]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CompanyAddress6Lbl, CompanyAddress[6]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CompanyAddress7Lbl, CompanyAddress[7]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CompanyAddress8Lbl, CompanyAddress[8]);
        LibraryReportDataset.AssertCurrentRowValueEquals(CompanyCityLbl, CompanyInformation.City);
        LibraryReportDataset.AssertCurrentRowValueEquals(ExpenseUserNameLbl, ExpenseReportHeader."Expense User Name");
        LibraryReportDataset.AssertCurrentRowValueEquals(ReportMonthLbl, Format(ExpenseReportHeader."Expense Report Date", 0, '<Month Text> <Year4>'));
        LibraryReportDataset.AssertCurrentRowValueEquals(HeaderDescriptionLbl, ExpenseReportHeader.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals(JobTitleLbl, ExpenseUser."Job Title");

        if MileageAmount <> 0 then
            VerifyMileageDataInExpenseReportSummaryPage(ExpenseReportHeader);

        if PerDiemAmount <> 0 then
            VerifyPerDiemDataInExpenseReportSummaryPage(ExpenseReportHeader);

        if OtherExpenseAmount <> 0 then
            VerifyOtherExpenseDataInExpenseReportSummaryPage(ExpenseReportHeader);
    end;

    local procedure VerifyMileageDataInExpenseReportSummaryPage(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
        MileageValue: Decimal;
        ExpectedAmountPerMileage: Decimal;
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.SetRange("Expense Detail Required", ExpenseReportLine."Expense Detail Required"::Mileage);
        if ExpenseReportLine.FindFirst() then begin
            MileageValue := ExpenseReportLine.Mileage;
            if MileageValue <> 0 then
                ExpectedAmountPerMileage := ExpenseReportLine."Amount (LCY)" / MileageValue
            else
                ExpectedAmountPerMileage := 0;

            LibraryReportDataset.AssertCurrentRowValueEquals(MileageStartingPointLbl, ExpenseReportLine."Starting Point");
            LibraryReportDataset.AssertCurrentRowValueEquals(DocumentNoMileageLineLbl, ExpenseReportLine."Document No.");
            LibraryReportDataset.AssertCurrentRowValueEquals(MileageLineNoLbl, ExpenseReportLine."Line No.");
            LibraryReportDataset.AssertCurrentRowValueEquals(MileageEndingPointLbl, ExpenseReportLine."Ending Point");
            LibraryReportDataset.AssertCurrentRowValueEquals(MileageMileageLbl, MileageValue);
            LibraryReportDataset.AssertCurrentRowValueEquals(MileageUOMLbl, ExpenseReportLine."Unit of Measure Code");
            LibraryReportDataset.AssertCurrentRowValueEquals(MileageAmountPerMileageLbl, ExpectedAmountPerMileage);
            LibraryReportDataset.AssertCurrentRowValueEquals(MileageAmountLCYLbl, ExpenseReportLine."Amount (LCY)");
        end;
    end;

    local procedure VerifyPerDiemDataInExpenseReportSummaryPage(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
        PerDiemUnitAmount: Decimal;
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.SetRange("Expense Detail Required", ExpenseReportLine."Expense Detail Required"::"Per Diem");
        if ExpenseReportLine.FindFirst() then begin
            LibraryReportDataset.AssertCurrentRowValueEquals(PerDiemExpenseLocationLbl, GetExpenseLocationDescription(ExpenseReportLine."Expense Location"));
            LibraryReportDataset.AssertCurrentRowValueEquals(PerDiemLineNoLbl, ExpenseReportLine."Line No.");
            LibraryReportDataset.AssertCurrentRowValueEquals(PerDiemCurrencyLbl, ExpenseReportLine."Expense Currency Code");
            LibraryReportDataset.AssertCurrentRowValueEquals(DocumentNoPerDiemLineLbl, ExpenseReportLine."Document No.");

            PerDiemUnitAmount := GetPerDiemUnitAmount(ExpenseReportHeader."No.", ExpenseReportLine."Line No.");
            LibraryReportDataset.AssertCurrentRowValueEquals(PerDiemAmountLbl, ExpenseReportLine.Amount);
            LibraryReportDataset.AssertCurrentRowValueEquals(PerDiemUnitAmountLbl, PerDiemUnitAmount);
        end;
    end;

    local procedure VerifyOtherExpenseDataInExpenseReportSummaryPage(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.SetFilter("Expense Detail Required", '<>%1&<>%2',
            ExpenseReportLine."Expense Detail Required"::"Per Diem",
            ExpenseReportLine."Expense Detail Required"::Mileage);
        if ExpenseReportLine.FindFirst() then begin
            LibraryReportDataset.AssertCurrentRowValueEquals(OtherCategoryLbl, GetExpenseCategoryDescription(ExpenseReportLine."Expense Category"));
            LibraryReportDataset.AssertCurrentRowValueEquals(OtherLineNoLbl, ExpenseReportLine."Line No.");
            if ExpenseReportLine.Refundable then
                LibraryReportDataset.AssertCurrentRowValueEquals(OtherRefundableAmountLCYLbl, ExpenseReportLine."Amount (LCY)" - ExpenseReportLine."Non-Refundable Amount (LCY)")
            else
                LibraryReportDataset.AssertCurrentRowValueEquals(OtherRefundableAmountLCYLbl, 0);
            LibraryReportDataset.AssertCurrentRowValueEquals(DocumentNoOtherExpenseLineLbl, ExpenseReportLine."Document No.");
        end;
    end;

    local procedure RunExpenseReportDetail(ExpenseReportHeader: Record "Expense Report Header")
    begin
        ExpenseReportHeader.SetRange("No.", ExpenseReportHeader."No.");
        Report.Run(Report::"Expense Report Details", true, false, ExpenseReportHeader);
        LibraryReportDataset.LoadDataSetFile();
    end;

    local procedure CreateExpenseReport(var ExpenseUser: Record "Expense User"; var ExpenseReportHeader: Record "Expense Report Header"; var CurrencyCode: Code[10])
    begin
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');
        ExpenseReportHeader."Posting Date" := WorkDate();
        ExpenseReportHeader."Expense Report Date" := WorkDate();
        ExpenseReportHeader.Description := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(ExpenseReportHeader.Description));
        ExpenseReportHeader."Anti-Corruption Attestation" := true;
        ExpenseReportHeader."Anti-Corruption Description" := CopyStr(LibraryRandom.RandText(40), 1, MaxStrLen(ExpenseReportHeader."Anti-Corruption Description"));
        ExpenseReportHeader.Modify(true);
    end;

    local procedure UpdatePerDiemInExpenseAgentSetup()
    begin
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);
    end;

    local procedure CreateAndAttachExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; Expense: Record Expense)
    var
        CreateExpReport: Codeunit "Create Expense Report";
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");
        CreateExpReport.AddExpensesToReport(ExpenseReportHeader);
    end;

    local procedure VerifyMissingExpenseReportLocationNotification(ExpenseReportNo: Code[20]; LineNo: Integer)
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.Get(ExpenseReportNo, LineNo);

        Assert.ExpectedMessage(
            StrSubstNo(ExpenseReportLocationMissingMsg, ExpenseReportLine.FieldCaption("Expense Location"), ExpenseReportLine."Document No.", ExpenseReportLine."Line No."),
            LibraryVariableStorage.DequeueText()); // from SentNotificationHandler

        LibraryVariableStorage.AssertEmpty();
        Clear(ExpenseReportLine);
        LibraryNotificationMgt.RecallNotificationsForRecord(ExpenseReportLine);
    end;

    local procedure GetExpenseLocationDescription(ExpenseLocationCode: Code[20]): Text[100]
    var
        ExpenseLocation: Record "Expense Location";
    begin
        if ExpenseLocation.Get(ExpenseLocationCode) then
            exit(ExpenseLocation.Description);
        exit(ExpenseLocationCode);
    end;

    local procedure GetExpenseCategoryDescription(ExpenseCategoryCode: Code[20]): Text[100]
    var
        ExpenseCategory: Record "Expense Category";
    begin
        if ExpenseCategory.Get(ExpenseCategoryCode) then
            exit(ExpenseCategory."Posting Description");
        exit(ExpenseCategoryCode);
    end;

    local procedure GetPerDiemUnitAmount(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer): Decimal
    var
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
    begin
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportNo);
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLineNo);
        if ExpenseReportLinePerDiem.FindFirst() then
            exit(ExpenseReportLinePerDiem."Original Per Diem Amount")
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

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExpenseReportLineItemsEditableModalPageHandler(var ExpenseReportLineItemization: TestPage "Expense Report Line Items")
    begin
        Assert.AreEqual(
            true,
            ExpenseReportLineItemization.Editable,
            StrSubstNo(PageMustBeEditableErr, ExpenseReportLineItemization.Caption()));
        ExpenseReportLineItemization.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExpenseReportLinePerDiemEditableModalPageHandler(var ExpenseReportLinePerDiem: TestPage "Expense Report Line Per Diems")
    begin
        Assert.AreEqual(
            true,
            ExpenseReportLinePerDiem.Editable,
            StrSubstNo(PageMustBeEditableErr, ExpenseReportLinePerDiem.Caption()));
        ExpenseReportLinePerDiem.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExpenseReportLineParticipantsEditableModalPageHandler(var ExpenseReportLineParticipants: TestPage "Expense Report Line Particips")
    begin
        Assert.AreEqual(
            true,
            ExpenseReportLineParticipants.Editable,
            StrSubstNo(PageMustBeEditableErr, ExpenseReportLineParticipants.Caption()));
        ExpenseReportLineParticipants.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExpenseReportLinePerDiemWithRuleModalPageHandler(var ExpenseReportLinePerDiem: TestPage "Expense Report Line Per Diems")
    begin
        Assert.AreEqual(
            false,
            ExpenseReportLinePerDiem.Description.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportLinePerDiem.Description.Caption(), ExpenseReportLinePerDiem.Caption()));
        Assert.AreEqual(
            false,
            ExpenseReportLinePerDiem.Date.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportLinePerDiem.Date.Caption(), ExpenseReportLinePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpenseReportLinePerDiem.Breakfast.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportLinePerDiem.Breakfast.Caption(), ExpenseReportLinePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpenseReportLinePerDiem.Lunch.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportLinePerDiem.Lunch.Caption(), ExpenseReportLinePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpenseReportLinePerDiem.Dinner.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportLinePerDiem.Dinner.Caption(), ExpenseReportLinePerDiem.Caption()));
        Assert.AreEqual(
            false,
            ExpenseReportLinePerDiem."Per Diem Amount".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportLinePerDiem."Per Diem Amount".Caption(), ExpenseReportLinePerDiem.Caption()));
        ExpenseReportLinePerDiem.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PerDiemExpenseReportWithNoRuleModalPageHandler(var ExpenseReportLinePerDiem: TestPage "Expense Report Line Per Diems")
    begin
        Assert.AreEqual(
            false,
            ExpenseReportLinePerDiem.Description.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportLinePerDiem.Description.Caption(), ExpenseReportLinePerDiem.Caption()));
        Assert.AreEqual(
            false,
            ExpenseReportLinePerDiem.Date.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportLinePerDiem.Date.Caption(), ExpenseReportLinePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpenseReportLinePerDiem.Breakfast.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportLinePerDiem.Breakfast.Caption(), ExpenseReportLinePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpenseReportLinePerDiem.Lunch.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportLinePerDiem.Lunch.Caption(), ExpenseReportLinePerDiem.Caption()));
        Assert.AreEqual(
            true,
            ExpenseReportLinePerDiem.Dinner.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportLinePerDiem.Dinner.Caption(), ExpenseReportLinePerDiem.Caption()));
        Assert.AreEqual(
            false,
            ExpenseReportLinePerDiem."Per Diem Amount".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseReportLinePerDiem."Per Diem Amount".Caption(), ExpenseReportLinePerDiem.Caption()));
        ExpenseReportLinePerDiem.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewPerDiemExpenseReportWithoutRuleModalPageErrorHandler(var ExpenseReportLinePerDiem: TestPage "Expense Report Line Per Diems")
    begin
        asserterror ExpenseReportLinePerDiem.New();

        Assert.ExpectedError(CannotInsertPerDiemInfoErr);
        ExpenseReportLinePerDiem.Ok().Invoke();
    end;

    [ModalPageHandler]
    procedure AddExpenseItemizationsWithSubCategoryHandler(var ExpenseReportLineItemizationsPage: TestPage "Expense Report Line Items")
    begin
        ExpenseReportLineItemizationsPage."Expense Subcategory Code".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseReportLineItemizationsPage.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        ExpenseReportLineItemizationsPage."Daily Rate".SetValue(LibraryVariableStorage.DequeueDecimal());

        ExpenseReportLineItemizationsPage.New();
        ExpenseReportLineItemizationsPage."Expense Subcategory Code".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseReportLineItemizationsPage.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        ExpenseReportLineItemizationsPage."Daily Rate".SetValue(LibraryVariableStorage.DequeueDecimal());
        ExpenseReportLineItemizationsPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VerifyQuantityInExpenseReportItemizationsModalPageHandler(var ExpenseReportLineItemizationsPage: TestPage "Expense Report Line Items")
    begin
        ExpenseReportLineItemizationsPage.Quantity.AssertEquals(LibraryVariableStorage.DequeueInteger());
        ExpenseReportLineItemizationsPage.OK().Invoke();
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

    [ModalPageHandler]
    procedure PerDiemExpenseReportWithoutRuleModalPageErrorHandler(var ExpenseReportLinePerDiem: TestPage "Expense Report Line Per Diems")
    begin
        ExpenseReportLinePerDiem.Ok().Invoke();
    end;

    [MessageHandler]
    procedure ExactMessageHandler(Msg: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Msg);
    end;

    [RequestPageHandler]
    procedure ExpenseReportDetailsRequestPageHandler(var ExpenseReportDetails: TestRequestPage "Expense Report Details")
    begin
        ExpenseReportDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [SendNotificationHandler]
    procedure SentNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;
}
