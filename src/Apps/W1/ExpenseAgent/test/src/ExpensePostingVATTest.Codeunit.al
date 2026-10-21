// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Purchases.Vendor;
using System.Environment;
using System.TestLibraries.Utilities;

codeunit 148330 "Expense Posting VAT Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryJob: Codeunit "Library - Job";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        CanModifyLinesQst: Label 'You have modified %1 which will also update the lines.\\Do you want to continue?', Comment = '%1 = Field Caption';
        NotApprovedForVATReclaimCategoryErr: Label 'VAT Reclaim Status is not set for Line with Expense Category %1.', Comment = '%1 = Expense Category';
        NotApprovedForVATReclaimErr: Label 'VAT Reclaim Status is not set for Line with Expense Category %1 and Expense Subcategory %2.', Comment = '%1 = Expense Category, %2 = Expense Subcategory';
        ModifyOrDeleteAgentVATSpecErr: Label 'Modifications and delete are not allowed for records created by the Expense Agent API.';
        RoundingDifferenceTooLargeErr: Label 'exceeds the currency rounding precision';

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure HotelMultiSubcatDiffVAT()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[4] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLineItem: Record "Posted Exp. Rep. Line Item";
        Employee: Record Employee;
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
    begin
        // [SCENARIO] Posting hotel expense with multiple subcategories at different VAT rates
        Initialize();

        // [GIVEN] Employee "E" and HOTEL category with subcategories at different VAT rates (10%, 10%, 20%, 0%)
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[3], ExpenseCategory.Code, 20, VATPostingSetup[2]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[4], ExpenseCategory.Code, 0, VATPostingSetup[3]);

        // [GIVEN] Expense "EXP" for employee "E" with category HOTELS
        // [GIVEN] Itemization with subcategory[1] for 100, subcategory[2] for 20, subcategory[3] for 30, subcategory[4] for 10
        CreateExpenseWithItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup);

        // [WHEN] Expense report is created and posted for expense "EXP"
        PostExpenseReport(ExpenseReportHeader, Expense, ExpenseUser);

        // [THEN] Posted expense report contains all 4 itemization lines
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        PostedExpenseReportLineItem.SetRange("Expense Report No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(PostedExpenseReportLineItem, 4);

        // [THEN] Itemization lines have correct amounts
        VerifyPostedItemizationLine(PostedExpenseReportHeader."No.", ExpenseSubCategory[1].Code, 100);
        VerifyPostedItemizationLine(PostedExpenseReportHeader."No.", ExpenseSubCategory[2].Code, 20);
        VerifyPostedItemizationLine(PostedExpenseReportHeader."No.", ExpenseSubCategory[3].Code, 30);
        VerifyPostedItemizationLine(PostedExpenseReportHeader."No.", ExpenseSubCategory[4].Code, 10);

        // [THEN] VAT entries are created with correct amounts: 10% rate (subcategories 1+2: 109.09 base, 10.91 VAT), 20% rate (subcategory 3: 25 base, 5 VAT)
        VerifyVATEntryByPostingGroup(PostedExpenseReportHeader."No.", VATPostingSetup[1], 109.09, 10.91);
        VerifyVATEntryByPostingGroup(PostedExpenseReportHeader."No.", VATPostingSetup[2], 25, 5);

        // [THEN] GL entries created with correct VAT amounts for each subcategory
        Employee.Get(ExpenseUser."Employee No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccount(ExpenseCategory.Code), 144.09);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure MultipleVATSpecificationsPostCompleteAmountToProject()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[4] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
    begin
        // [SCENARIO] A project receives the complete expense-line amount when the line has multiple VAT specifications.
        Initialize();

        // [GIVEN] An expense assigned to a project with two VAT specifications whose LCY bases total 200.
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 20, VATPostingSetup[2]);
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 110, 120, 0, 0);
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        Expense.PerformManualReopen(Expense);
        Expense.Get(Expense."No.");
        Expense.Validate("Job No.", JobTask."Job No.");
        Expense.Validate("Job Task No.", JobTask."Job Task No.");
        Expense.Modify(true);
        ReleaseExpenseAndUpdateAccounts(Expense, ExpenseUser);

        // [WHEN] The expense report is posted.
        PostExpenseReport(ExpenseReportHeader, Expense, ExpenseUser);

        // [THEN] One project ledger entry contains the sum of both specification journal amounts.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportLine.FindFirst();
#pragma warning disable AA0210
        JobLedgerEntry.SetRange("Expense Report No.", PostedExpenseReportHeader."No.");
        JobLedgerEntry.SetRange("Expense Report Line No.", PostedExpenseReportLine."Line No.");
#pragma warning restore AA0210
        JobLedgerEntry.FindFirst();
        Assert.RecordCount(JobLedgerEntry, 1);
        Assert.AreNearlyEqual(200, JobLedgerEntry."Unit Cost (LCY)", 0.01, 'Project unit cost must include all VAT specification journal amounts.');
        Assert.AreNearlyEqual(200, JobLedgerEntry."Unit Price (LCY)", 0.01, 'Project unit price must include all VAT specification journal amounts.');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure VATEntriesPerHotelSubcat()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[4] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [SCENARIO] VAT entries are created correctly for each hotel subcategory
        Initialize();

        // [GIVEN] Employee "E" and HOTEL category with subcategories at different VAT rates (10%, 20%, 10%, 0%)
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 20, VATPostingSetup[2]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[3], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[4], ExpenseCategory.Code, 0, VATPostingSetup[3]);

        // [GIVEN] Expense "EXP" for employee "E" with category HOTELS
        // [GIVEN] Itemization with subcategory[1] for 200, subcategory[2] for 15, subcategory[3] for 30, subcategory[4] for 5
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 200, 15, 30, 5);

        // [WHEN] Expense report is created and posted for expense "EXP"
        PostExpenseReport(ExpenseReportHeader, Expense, ExpenseUser);

        // [THEN] 3 VAT entries are created (one for each non-zero VAT rate)
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        VATEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        VATEntry.SetFilter(Amount, '<>%1', 0);
        Assert.RecordCount(VATEntry, 3);

        // [THEN] VAT entry for 10% rate with base 209.09 and amount 20.91
        VerifyVATEntryByPostingGroup(PostedExpenseReportHeader."No.", VATPostingSetup[1], 209.09, 20.91);

        // [THEN] VAT entry for 20% rate with base 12.5 and amount 2.5
        VerifyVATEntryByPostingGroup(PostedExpenseReportHeader."No.", VATPostingSetup[2], 12.5, 2.5);

        // [THEN] No VAT entry for 0% rate (subcategory 4)
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure HotelItemizeDiffDates()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[3] of Record "Expense Subcategory";
        ExpenseItemization: array[5] of Record "Expense Itemization";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLineItem: Record "Posted Exp. Rep. Line Item";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] Posting hotel expense with itemization across different dates
        Initialize();

        // [GIVEN] Employee "E" and HOTEL category with subcategories at 10% VAT rate
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 10, VATPostingSetup);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[3], ExpenseCategory.Code, 10, VATPostingSetup);

        // [GIVEN] Expense "EXP" for employee "E" with category HOTELS
        CreateExpenseForHotel(Expense, ExpenseUser, ExpenseCategory, VATPostingSetup, 345);

        // [GIVEN] Itemization for date D1 with subcategory[1] for 100
        LibraryExpense.CreateExpenseItemization(ExpenseItemization[1], Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, WorkDate(), 100, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, 100);

        // [GIVEN] Itemization for date D2 with subcategory[1] for 100 and subcategory[2] for 20
        LibraryExpense.CreateExpenseItemization(ExpenseItemization[2], Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, WorkDate() + 1, 100, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, 100);

        LibraryExpense.CreateExpenseItemization(ExpenseItemization[3], Expense, ExpenseCategory.Code, ExpenseSubCategory[2].Code, WorkDate() + 1, 20, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[2].Code, 20);

        // [GIVEN] Itemization for date D3 with subcategory[1] for 100 and subcategory[3] for 25
        LibraryExpense.CreateExpenseItemization(ExpenseItemization[4], Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, WorkDate() + 2, 100, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, 100);

        LibraryExpense.CreateExpenseItemization(ExpenseItemization[5], Expense, ExpenseCategory.Code, ExpenseSubCategory[3].Code, WorkDate() + 2, 25, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[3].Code, 25);

        ReleaseExpenseAndUpdateAccounts(Expense, ExpenseUser);

        // [WHEN] Expense report is created and posted for expense "EXP"
        PostExpenseReport(ExpenseReportHeader, Expense, ExpenseUser);

        // [THEN] Posted expense report contains 5 itemization lines (3 of subcategory[1], 1 of subcategory[2], 1 of subcategory[3])
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        PostedExpenseReportLineItem.SetRange("Expense Report No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(PostedExpenseReportLineItem, 5);

        // [THEN] Total amount is 345 with appropriate VAT distribution
        VerifyPostedItemizationTotal(PostedExpenseReportHeader."No.", 345);

        // [THEN] Each itemization line has correct date and subcategory
        VerifyPostedItemizationLineWithDate(PostedExpenseReportHeader."No.", ExpenseSubCategory[1].Code, WorkDate(), 100);
        VerifyPostedItemizationLineWithDate(PostedExpenseReportHeader."No.", ExpenseSubCategory[1].Code, WorkDate() + 1, 100);
        VerifyPostedItemizationLineWithDate(PostedExpenseReportHeader."No.", ExpenseSubCategory[2].Code, WorkDate() + 1, 20);
        VerifyPostedItemizationLineWithDate(PostedExpenseReportHeader."No.", ExpenseSubCategory[1].Code, WorkDate() + 2, 100);
        VerifyPostedItemizationLineWithDate(PostedExpenseReportHeader."No.", ExpenseSubCategory[3].Code, WorkDate() + 2, 25);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure GLEntriesCorrectVATAmounts()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[3] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] GL entries have correct VAT amounts for each hotel subcategory
        Initialize();

        // [GIVEN] Employee "E" and HOTEL category with subcategories at different VAT rates (10%, 20%, 0%)
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 20, VATPostingSetup[2]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[3], ExpenseCategory.Code, 0, VATPostingSetup[3]);

        // [GIVEN] Expense "EXP" for employee "E" with category HOTELS
        // [GIVEN] Itemization with subcategory[1] for 110, subcategory[2] for 60, subcategory[3] for 15
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 110, 60, 15, 0);

        // [WHEN] Expense report is created and posted for expense "EXP"
        PostExpenseReport(ExpenseReportHeader, Expense, ExpenseUser);

        // [THEN] GL entry has correct amounts with VAT
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        VerifyGLEntryWithVAT(PostedExpenseReportHeader."No.", GetRefundableDebitAccount(ExpenseCategory.Code), 165, 20);

        // [THEN] Total GL amount equals posted expense amount of 165
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.SetRange("G/L Account No.", GetRefundableDebitAccount(ExpenseCategory.Code));
        GLEntry.CalcSums(Amount);
        Assert.AreNearlyEqual(165, GLEntry.Amount, 0.01, 'Total GL amount must equal 165');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure HotelRefundableSubcat()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[3] of Record "Expense Subcategory";
        ExpenseItemization: array[3] of Record "Expense Itemization";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLineItem: Record "Posted Exp. Rep. Line Item";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] Posting hotel expense with both refundable and non-refundable subcategories
        Initialize();

        // [GIVEN] Employee "E" and HOTEL category with refundable and non-refundable subcategories
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup);
        ExpenseSubCategory[1].Validate(Refundable, true);
        ExpenseSubCategory[1].Modify();

        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 10, VATPostingSetup);
        ExpenseSubCategory[2].Validate(Refundable, true);
        ExpenseSubCategory[2].Modify();

        CreateSubcategoryWithVATRate(ExpenseSubCategory[3], ExpenseCategory.Code, 10, VATPostingSetup);
        ExpenseSubCategory[3].Validate(Refundable, false);
        ExpenseSubCategory[3].Modify();

        // [GIVEN] Expense "EXP" for employee "E" with category HOTELS
        CreateExpenseForHotel(Expense, ExpenseUser, ExpenseCategory, VATPostingSetup, 170);

        // [GIVEN] Itemization with subcategory[1] for 100, subcategory[2] for 20, subcategory[3] for 50 (non-refundable)
        LibraryExpense.CreateExpenseItemization(ExpenseItemization[1], Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, WorkDate(), 100, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, 100);

        LibraryExpense.CreateExpenseItemization(ExpenseItemization[2], Expense, ExpenseCategory.Code, ExpenseSubCategory[2].Code, WorkDate(), 20, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[2].Code, 20);

        LibraryExpense.CreateExpenseItemization(ExpenseItemization[3], Expense, ExpenseCategory.Code, ExpenseSubCategory[3].Code, WorkDate(), 50, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[3].Code, 50);

        ReleaseExpenseAndUpdateAccounts(Expense, ExpenseUser);

        // [WHEN] Expense report is created and posted for expense "EXP"
        PostExpenseReport(ExpenseReportHeader, Expense, ExpenseUser);

        // [THEN] Posted expense report contains 3 itemization lines
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        PostedExpenseReportLineItem.SetRange("Expense Report No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(PostedExpenseReportLineItem, 3);

        // [THEN] Total amount is 170 with appropriate VAT
        VerifyPostedItemizationTotal(PostedExpenseReportHeader."No.", 170);

        // [THEN] Subcategory[3] is marked as non-refundable in posted lines
        if PostedExpenseReportLineItem.FindSet() then
            repeat
                if PostedExpenseReportLineItem."Expense Subcategory Code" = ExpenseSubCategory[3].Code then
                    Assert.AreEqual(false, PostedExpenseReportLineItem.Refundable, 'Subcategory[3] should be non-refundable');
            until PostedExpenseReportLineItem.Next() = 0;

        // [THEN] GL entries correctly reflect refundable and non-refundable amounts
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccount(ExpenseCategory.Code), 154.54);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure VATSpecApprovedAndRejectedLines()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[3] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] Posting expense with some VAT spec lines Approved and some Rejected
        Initialize();

        // [GIVEN] Employee "E" and HOTEL category with 3 subcategories at different VAT rates (10%, 20%, 10%)
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 20, VATPostingSetup[2]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[3], ExpenseCategory.Code, 10, VATPostingSetup[3]);

        // [GIVEN] Expense "EXP" with itemizations: subcategory[1] for 100, subcategory[2] for 50, subcategory[3] for 80
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 100, 50, 80, 0);

        // [GIVEN] Expense report is created with expenses added
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);
        UpdateExpenseReportVATSpecLineStatuses(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Expense report is posted
        PostExpenseReportWithConfirmation(ExpenseReportPost, ExpenseReportHeader);

        // [THEN] Posted expense report is created
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);

        // [THEN] VAT entries are created only for Approved lines
        // First subcategory (10% Approved): should have VAT entry
        VerifyVATEntryByPostingGroup(PostedExpenseReportHeader."No.", VATPostingSetup[1], 90.91, 9.09);

        // Second subcategory (20% Rejected): should NOT have VAT entry
        VATEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup[2]."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup[2]."VAT Prod. Posting Group");
        Assert.RecordCount(VATEntry, 0);

        // Third subcategory (10% Approved): should have VAT entry
        VerifyVATEntryByPostingGroup(PostedExpenseReportHeader."No.", VATPostingSetup[3], 72.73, 7.27);

        // [THEN] Rejected line is posted as gross amount (base + VAT), so one entry of 50.00 must exist.
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.SetRange("G/L Account No.", GetRefundableDebitAccount(ExpenseCategory.Code));
        GLEntry.SetRange(Amount, 50);
        Assert.RecordCount(GLEntry, 1);

        // [THEN] Posted VAT spec lines reflect the approval status
        PostedExpenseReportLineVATSpec.SetRange("Expense Report No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportLineVATSpec.SetRange("VAT Prod. Posting Group", VATPostingSetup[2]."VAT Prod. Posting Group");
        Assert.RecordCount(PostedExpenseReportLineVATSpec, 1);
        PostedExpenseReportLineVATSpec.FindFirst();
        Assert.AreEqual(PostedExpenseReportLineVATSpec."Reclaim Status"::Rejected, PostedExpenseReportLineVATSpec."Reclaim Status", 'Rejected line should maintain Rejected status');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure VATSpecPendingStatusBlocksPosting()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] Posting is blocked when any VAT spec row remains Pending.
        Initialize();

        // [GIVEN] Expense report with VAT spec lines where reclaim status is still Pending.
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 20, VATPostingSetup[2]);
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 100, 50, 0, 0);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");
        UpdateExpenseReportLinesWithVendorKeepingPending(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Posting is attempted
        asserterror PostExpenseReportWithConfirmation(ExpenseReportPost, ExpenseReportHeader);

        // [THEN] A reclaim-status error is raised and posting does not create a posted report.
        Assert.ExpectedError(StrSubstNo(NotApprovedForVATReclaimErr, ExpenseCategory.Code, ExpenseSubCategory[1].Code));
        LibraryVariableStorage.AssertEmpty();
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordCount(PostedExpenseReportHeader, 0);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure MaterialVATSpecificationDifferenceBlocksPosting()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[4] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] A material difference between an expense report line and its VAT specifications blocks posting.
        Initialize();

        // [GIVEN] An LCY expense report whose VAT specification total is lower than the line amount by 1.00.
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 110, 0, 0, 0);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLineVATSpec.SetFilter("Document Line No.", '<>%1', 0);
        ExpenseReportLineVATSpec.FindFirst();
        ExpenseReportLineVATSpec."VAT Base Amount (RCY)" -= 1;
        ExpenseReportLineVATSpec."VAT Base Amount (LCY)" -= 1;
        ExpenseReportLineVATSpec.Modify(false);
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.FindFirst();
        ExpenseReportLineVATSpec.CalcSums("VAT Base Amount (RCY)", "VAT Amount (RCY)", "VAT Base Amount (LCY)", "VAT Amount (LCY)");
        Assert.AreNearlyEqual(
            1, ExpenseReportLine."Reimbursable Amount" - ExpenseReportLineVATSpec."VAT Base Amount (RCY)" - ExpenseReportLineVATSpec."VAT Amount (RCY)", 0.01,
            'The test must create a material reimbursement-currency difference.');
        Assert.AreNearlyEqual(
            1, ExpenseReportLine."Reimbursable Amount (LCY)" - ExpenseReportLineVATSpec."VAT Base Amount (LCY)" - ExpenseReportLineVATSpec."VAT Amount (LCY)", 0.01,
            'The test must create a material local-currency difference.');

        // [WHEN] Posting is attempted.
        asserterror PostExpenseReportWithConfirmation(ExpenseReportPost, ExpenseReportHeader);

        // [THEN] The material difference is not reclassified to an expense rounding account.
        Assert.ExpectedError(RoundingDifferenceTooLargeErr);
        LibraryVariableStorage.AssertEmpty();
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordCount(PostedExpenseReportHeader, 0);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure VATSpecWithoutSubcategoryPendingStatusBlocksPosting()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] Posting is blocked when a category-only VAT specification remains pending.
        Initialize();

        // [GIVEN] A non-itemized expense with a category-level VAT specification.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        CreateSubcategoryWithVATRate(ExpenseSubCategory, ExpenseCategory.Code, 20, VATPostingSetup);
        ExpenseCategory.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ExpenseCategory.Validate("Default VAT %", VATPostingSetup."VAT %");
        ExpenseCategory.Modify(true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', 120);
        Expense.UpdateVATSpecification(Expense."No.");
        ReleaseExpenseAndUpdateAccounts(Expense, ExpenseUser);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");
        UpdateExpenseReportLinesWithVendorKeepingPending(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Posting is attempted.
        asserterror PostExpenseReportWithConfirmation(ExpenseReportPost, ExpenseReportHeader);

        // [THEN] The error identifies the expense category without requiring a subcategory.
        Assert.ExpectedError(StrSubstNo(NotApprovedForVATReclaimCategoryErr, ExpenseCategory.Code));
        LibraryVariableStorage.AssertEmpty();
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordCount(PostedExpenseReportHeader, 0);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure InactiveVATSpecExpenseCategoryBlocksPosting()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        VATSpecExpenseCategory: Record "Expense Category";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        VATPostingSetup: Record "VAT Posting Setup";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] Posting is blocked when a VAT specification references an inactive expense category.
        Initialize();

        // [GIVEN] An expense report whose parent line references active expense masters.
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubcategory, ExpenseCategory.Code, 20, VATPostingSetup);
        CreateExpenseForHotel(Expense, ExpenseUser, ExpenseCategory, VATPostingSetup, 120);
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseCategory.Code, ExpenseSubcategory.Code, WorkDate(), 120, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubcategory.Code, 120);
        ReleaseExpenseAndUpdateAccounts(Expense, ExpenseUser);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);

        // [GIVEN] The VAT specification references a different category that becomes inactive after release.
        LibraryExpense.CreateExpenseCategory(VATSpecExpenseCategory, VATSpecExpenseCategory."Reimbursement Type"::"Employee Paid", VATSpecExpenseCategory."Expense Detail Required"::" ");
        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLineVATSpec.FindFirst();
        ExpenseReportLineVATSpec."Expense Category" := VATSpecExpenseCategory.Code;
        ExpenseReportLineVATSpec."Expense Subcategory" := '';
        ExpenseReportLineVATSpec.Modify();
        ExpenseReportHeader.PerformManualRelease();
        VATSpecExpenseCategory.Validate(Inactive, true);
        VATSpecExpenseCategory.Modify(true);

        // [WHEN] Posting is attempted.
        asserterror PostExpenseReportWithConfirmation(ExpenseReportPost, ExpenseReportHeader);

        // [THEN] The inactive VAT-spec category blocks posting.
        Assert.ExpectedTestFieldError(VATSpecExpenseCategory.FieldCaption(Inactive), Format(false));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure InactiveVATSpecExpenseSubcategoryBlocksPosting()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseSubcategory: array[2] of Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        VATPostingSetup: Record "VAT Posting Setup";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO] Posting is blocked when a VAT specification references an inactive expense subcategory.
        Initialize();

        // [GIVEN] An expense report whose parent line references an active subcategory.
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubcategory[1], ExpenseCategory.Code, 20, VATPostingSetup);
        CreateSubcategoryWithVATRate(ExpenseSubcategory[2], ExpenseCategory.Code, 20, VATPostingSetup);
        CreateExpenseForHotel(Expense, ExpenseUser, ExpenseCategory, VATPostingSetup, 120);
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseCategory.Code, ExpenseSubcategory[2].Code, WorkDate(), 120, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubcategory[2].Code, 120);
        ReleaseExpenseAndUpdateAccounts(Expense, ExpenseUser);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] The subcategory referenced only by the VAT specification becomes inactive.
        ExpenseSubcategory[2].Validate(Inactive, true);
        ExpenseSubcategory[2].Modify(true);

        // [WHEN] Posting is attempted.
        asserterror PostExpenseReportWithConfirmation(ExpenseReportPost, ExpenseReportHeader);

        // [THEN] The inactive VAT-spec subcategory blocks posting.
        Assert.ExpectedTestFieldError(ExpenseSubcategory[2].FieldCaption(Inactive), Format(false));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure InactiveExpenseCategoryCannotBeValidatedOnVATSpec()
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
    begin
        // [SCENARIO] An inactive expense category cannot be selected on a VAT specification.
        Initialize();

        // [GIVEN] An inactive expense category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Inactive, true);
        ExpenseCategory.Modify(true);

        // [WHEN] The category is validated on a VAT specification.
        asserterror ExpenseReportLineVATSpec.Validate("Expense Category", ExpenseCategory.Code);

        // [THEN] The inactive category is rejected immediately.
        Assert.ExpectedTestFieldError(ExpenseCategory.FieldCaption(Inactive), Format(false));
    end;

    [Test]
    procedure InactiveExpenseSubcategoryCannotBeValidatedOnVATSpec()
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        ExpenseSubcategory: Record "Expense Subcategory";
    begin
        // [SCENARIO] An inactive expense subcategory cannot be selected on a VAT specification.
        Initialize();

        // [GIVEN] An active category with an inactive subcategory.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);
        ExpenseSubcategory.Validate(Inactive, true);
        ExpenseSubcategory.Modify(true);
        ExpenseReportLineVATSpec."Expense Category" := ExpenseCategory.Code;

        // [WHEN] The subcategory is validated on a VAT specification.
        asserterror ExpenseReportLineVATSpec.Validate("Expense Subcategory", ExpenseSubcategory.Code);

        // [THEN] The inactive subcategory is rejected immediately.
        Assert.ExpectedTestFieldError(ExpenseSubcategory.FieldCaption(Inactive), Format(false));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ModifiedVATSpecIsRecalculatedAndPostedInReimbursementCurrency()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[4] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
        ExpectedVATBaseAmountRCY: Decimal;
        ExpectedVATAmountRCY: Decimal;
    begin
        // [SCENARIO] A copied VAT specification can be changed and is posted in reimbursement currency.
        Initialize();

        // [GIVEN] An LCY expense for 110 with 10% VAT and an expense report in a foreign reimbursement currency.
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 110, 0, 0, 0);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 2);
        Currency.Get(CurrencyCode);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");

        // [WHEN] The VAT rate is changed to 20% on the copied specification.
        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLineVATSpec.FindFirst();
        ExpenseReportLineVATSpec.Validate("VAT %", 20);
        ExpenseReportLineVATSpec.Modify(true);

        // [THEN] Transaction, LCY, and reimbursement-currency amounts are recalculated from the gross amount.
        ExpectedVATBaseAmountRCY :=
            Round(
                CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                    ExpenseReportHeader."Posting Date", CurrencyCode, ExpenseReportLineVATSpec."VAT Base Amount (LCY)",
                    ExpenseReportHeader."Reimbursement Currency Factor"),
                Currency."Amount Rounding Precision");
        ExpectedVATAmountRCY :=
            Round(
                CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                    ExpenseReportHeader."Posting Date", CurrencyCode, ExpenseReportLineVATSpec."VAT Amount (LCY)",
                    ExpenseReportHeader."Reimbursement Currency Factor"),
                Currency."Amount Rounding Precision");
        Assert.AreNearlyEqual(91.67, ExpenseReportLineVATSpec."VAT Base Amount", 0.01, 'VAT base amount must be recalculated.');
        Assert.AreNearlyEqual(18.33, ExpenseReportLineVATSpec."VAT Amount", 0.01, 'VAT amount must be recalculated.');
        Assert.AreNearlyEqual(ExpectedVATBaseAmountRCY, ExpenseReportLineVATSpec."VAT Base Amount (RCY)", 0.01, 'VAT base amount in reimbursement currency must be calculated from LCY.');
        Assert.AreNearlyEqual(ExpectedVATAmountRCY, ExpenseReportLineVATSpec."VAT Amount (RCY)", 0.01, 'VAT amount in reimbursement currency must be calculated from LCY.');
        Assert.AreNearlyEqual(ExpectedVATBaseAmountRCY + ExpectedVATAmountRCY, ExpenseReportLineVATSpec."Amount (RCY)", 0.01, 'Gross amount in reimbursement currency must equal base plus VAT.');

        // [WHEN] The report is approved for reclaim and posted.
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();
        PostExpenseReportWithConfirmation(ExpenseReportPost, ExpenseReportHeader);

        // [THEN] The VAT specification journal line is posted with RCY as source currency and LCY as G/L amount.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        PostedExpenseReportLineVATSpec.SetRange("Expense Report No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportLineVATSpec.SetFilter("Expense Report Line No.", '<>%1', 0);
        PostedExpenseReportLineVATSpec.FindFirst();
        Assert.AreNearlyEqual(ExpectedVATBaseAmountRCY, PostedExpenseReportLineVATSpec."VAT Base Amount (RCY)", 0.01, 'Posted VAT base amount in reimbursement currency must be retained.');
        Assert.AreNearlyEqual(ExpectedVATAmountRCY, PostedExpenseReportLineVATSpec."VAT Amount (RCY)", 0.01, 'Posted VAT amount in reimbursement currency must be retained.');
        Assert.AreNearlyEqual(ExpectedVATBaseAmountRCY + ExpectedVATAmountRCY, PostedExpenseReportLineVATSpec."Amount (RCY)", 0.01, 'Posted gross amount in reimbursement currency must be retained.');
        Assert.AreNearlyEqual(ExpectedVATAmountRCY, PostedExpenseReportLineVATSpec."Reclaim VAT Amount (RCY)", 0.01, 'Posted reclaim VAT amount in reimbursement currency must be retained.');
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.SetRange("G/L Account No.", GetRefundableDebitAccount(ExpenseCategory.Code));
        GLEntry.SetRange("Source Currency Code", CurrencyCode);
        GLEntry.SetRange(Description, CopyStr(Expense.Description + ' / ' + ExpenseSubCategory[1]."Posting Description", 1, MaxStrLen(GLEntry.Description)));
        GLEntry.CalcSums(Amount, "Source Currency Amount", "Source Currency VAT Amount");
        Assert.AreNearlyEqual(ExpenseReportLineVATSpec."VAT Base Amount (LCY)", GLEntry.Amount, 0.01, 'Posted G/L amount must use the VAT specification LCY base.');
        Assert.AreNearlyEqual(ExpectedVATBaseAmountRCY, GLEntry."Source Currency Amount", 0.01, 'Posted source currency amount must use the VAT specification reimbursement amount.');
        Assert.AreNearlyEqual(ExpectedVATAmountRCY, GLEntry."Source Currency VAT Amount", 0.01, 'Posted source currency VAT amount must use the VAT specification reimbursement amount.');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReopenedReportRecalculatesVATSpecWhenReimbursementCurrencyFactorChanges()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[4] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        CreateExpenseReport: Codeunit "Create Expense Report";
        CurrencyCode: Code[10];
        InitialVATBaseAmountRCY: Decimal;
        InitialVATAmountRCY: Decimal;
    begin
        // [SCENARIO] Changing the reimbursement currency factor on a reopened report recalculates existing VAT specifications.
        Initialize();

        // [GIVEN] A released report with an existing 20% VAT specification calculated at a reimbursement factor of 1.
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 20, VATPostingSetup[1]);
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 120, 0, 0, 0);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);

        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLineVATSpec.FindFirst();
        InitialVATBaseAmountRCY := ExpenseReportLineVATSpec."VAT Base Amount (RCY)";
        InitialVATAmountRCY := ExpenseReportLineVATSpec."VAT Amount (RCY)";

        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportHeader.PerformManualReopen(ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [WHEN] The reimbursement currency factor is changed to 2 after reopening the report.
        LibraryVariableStorage.Enqueue(StrSubstNo(CanModifyLinesQst, ExpenseReportHeader.FieldCaption("Reimbursement Currency Factor")));
        LibraryVariableStorage.Enqueue(true);
        ExpenseReportHeader.Validate("Reimbursement Currency Factor", 2);
        ExpenseReportHeader.Modify(true);
        LibraryVariableStorage.AssertEmpty();

        // [THEN] The persisted VAT specification reimbursement amounts are recalculated using the new factor.
        ExpenseReportLineVATSpec.Get(
            ExpenseReportLineVATSpec."Document No.", ExpenseReportLineVATSpec."Document Line No.", ExpenseReportLineVATSpec."Line No.");
        Assert.AreNearlyEqual(InitialVATBaseAmountRCY * 2, ExpenseReportLineVATSpec."VAT Base Amount (RCY)", 0.01, 'VAT base amount in reimbursement currency must be recalculated.');
        Assert.AreNearlyEqual(InitialVATAmountRCY * 2, ExpenseReportLineVATSpec."VAT Amount (RCY)", 0.01, 'VAT amount in reimbursement currency must be recalculated.');
        Assert.AreNearlyEqual((InitialVATBaseAmountRCY + InitialVATAmountRCY) * 2, ExpenseReportLineVATSpec."Amount (RCY)", 0.01, 'Gross amount in reimbursement currency must be recalculated.');
        Assert.AreNearlyEqual(InitialVATAmountRCY * 2, ExpenseReportLineVATSpec."Reclaim VAT Amount (RCY)", 0.01, 'Reclaim VAT amount in reimbursement currency must be recalculated.');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PartialVATReclaimPostsReclaimAmountsAndNonDeductibleVAT()
    begin
        // [SCENARIO] A partially reclaimable VAT specification posts deductible and non-deductible VAT separately.
        VerifyPartialVATReclaimPosting(50, 50, 10, 50, 10, 10, 20);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure AsymmetricPartialVATReclaimPostsDifferentDeductibleAmounts()
    begin
        // [SCENARIO] An asymmetric partial reclaim keeps deductible and non-deductible VAT amounts distinct.
        VerifyPartialVATReclaimPosting(70, 70, 14, 30, 6, 14, 28);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure VATSpecPostingBalancesForeignReimbursementCurrency()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[4] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] Component rounding in a foreign reimbursement currency does not leave the G/L transaction out of balance.
        Initialize();

        // [GIVEN] A 200.02 LCY expense split into two VAT specs and an 8.56 reimbursement-currency exchange rate.
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 20, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 20, VATPostingSetup[1]);
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 100.01, 100.01, 0, 0);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 8.56);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");
        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLineVATSpec.FindFirst();
        ExpenseReportLineVATSpec."VAT Base Amount (LCY)" += 0.01;
        ExpenseReportLineVATSpec."VAT Base Amount (RCY)" += 0.08;
        ExpenseReportLineVATSpec."Amount (RCY)" += 0.08;
        ExpenseReportLineVATSpec.Modify();

        // [WHEN] The report is approved and posted.
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();
        PostExpenseReportWithConfirmation(ExpenseReportPost, ExpenseReportHeader);

        // [THEN] The document balances in LCY and reimbursement currency.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.CalcSums(Amount, "Source Currency Amount");
        Assert.AreEqual(0, GLEntry.Amount, 'The posted G/L entries must balance in LCY.');
        Assert.AreEqual(0, GLEntry."Source Currency Amount", 'The posted G/L entries must balance in reimbursement currency.');
    end;

    [Test]
    procedure UpdateVATSpecificationCreatesSpecForNonItemizedExpense()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseVATSpecification: Record "Expense VAT Specification";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] Updating the VAT specification for a non-itemized expense creates one row from the expense category.
        Initialize();

        // [GIVEN] A non-itemized expense category with 20% VAT and an expense for 120 LCY.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        CreateSubcategoryWithVATRate(ExpenseSubCategory, ExpenseCategory.Code, 20, VATPostingSetup);
        ExpenseCategory.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ExpenseCategory.Validate("Default VAT %", VATPostingSetup."VAT %");
        ExpenseCategory.Modify(true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', 120);

        // [WHEN] The VAT specification is updated.
        Expense.UpdateVATSpecification(Expense."No.");

        // [THEN] One manual VAT specification contains the category defaults and calculated VAT amounts.
        ExpenseVATSpecification.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseVATSpecification, 1);
        ExpenseVATSpecification.FindFirst();
        Assert.AreEqual(ExpenseVATSpecification.Source::Manual, ExpenseVATSpecification.Source, 'The generated VAT specification must be manual.');
        Assert.AreEqual(ExpenseCategory.Code, ExpenseVATSpecification."Expense Category", 'The expense category must be copied.');
        Assert.AreEqual('', ExpenseVATSpecification."Expense Subcategory", 'A non-itemized VAT specification must not have a subcategory.');
        Assert.AreEqual(VATPostingSetup."VAT Bus. Posting Group", ExpenseVATSpecification."VAT Bus. Posting Group", 'The default VAT business posting group must be used.');
        Assert.AreEqual(VATPostingSetup."VAT Prod. Posting Group", ExpenseVATSpecification."VAT Prod. Posting Group", 'The category VAT product posting group must be used.');
        Assert.AreNearlyEqual(20, ExpenseVATSpecification."VAT %", 0.01, 'The category VAT percentage must be used.');
        Assert.AreNearlyEqual(120, ExpenseVATSpecification.Amount, 0.01, 'The expense amount must be used.');
        Assert.AreNearlyEqual(100, ExpenseVATSpecification."VAT Base Amount", 0.01, 'The VAT base amount must be calculated.');
        Assert.AreNearlyEqual(20, ExpenseVATSpecification."VAT Amount", 0.01, 'The VAT amount must be calculated.');
    end;

    [Test]
    procedure UpdateVATSpecificationPreservesSubcategoryForNonItemizedExpense()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseVATSpecification: Record "Expense VAT Specification";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
    begin
        // [SCENARIO] Updating the VAT specification for a non-itemized expense preserves its subcategory VAT defaults.
        Initialize();

        // [GIVEN] A non-itemized category with 10% VAT and a selected subcategory with 20% VAT.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 20, VATPostingSetup[2]);
        ExpenseCategory.Validate("VAT Prod. Posting Group", VATPostingSetup[1]."VAT Prod. Posting Group");
        ExpenseCategory.Validate("Default VAT %", VATPostingSetup[1]."VAT %");
        ExpenseCategory.Modify(true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory[2].Code, '', true, '', 120);

        // [WHEN] The VAT specification is updated.
        Expense.UpdateVATSpecification(Expense."No.");

        // [THEN] The generated row retains the selected subcategory and uses its VAT defaults for the amounts.
        ExpenseVATSpecification.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseVATSpecification, 1);
        ExpenseVATSpecification.FindFirst();
        Assert.AreEqual(ExpenseCategory.Code, ExpenseVATSpecification."Expense Category", 'The expense category must be copied.');
        Assert.AreEqual(ExpenseSubCategory[2].Code, ExpenseVATSpecification."Expense Subcategory", 'The expense subcategory must be copied.');
        Assert.AreEqual(VATPostingSetup[2]."VAT Prod. Posting Group", ExpenseVATSpecification."VAT Prod. Posting Group", 'The subcategory VAT product posting group must be used.');
        Assert.AreNearlyEqual(20, ExpenseVATSpecification."VAT %", 0.01, 'The subcategory VAT percentage must be used.');
        Assert.AreNearlyEqual(100, ExpenseVATSpecification."VAT Base Amount", 0.01, 'The VAT base amount must use the subcategory VAT percentage.');
        Assert.AreNearlyEqual(20, ExpenseVATSpecification."VAT Amount", 0.01, 'The VAT amount must use the subcategory VAT percentage.');
    end;

    [Test]
    procedure UpdateVATSpecificationCreatesSpecForZeroRatedNonItemizedExpense()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseVATSpecification: Record "Expense VAT Specification";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] Updating the VAT specification preserves the 0% bucket for a non-itemized expense.
        Initialize();

        // [GIVEN] A zero-rated non-itemized category with a VAT product posting group and an expense for 120 LCY.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        CreateSubcategoryWithVATRate(ExpenseSubCategory, ExpenseCategory.Code, 0, VATPostingSetup);
        ExpenseCategory.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ExpenseCategory.Validate("Default VAT %", VATPostingSetup."VAT %");
        ExpenseCategory.Modify(true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', 120);

        // [WHEN] The VAT specification is updated.
        Expense.UpdateVATSpecification(Expense."No.");

        // [THEN] One zero-rated VAT specification retains the category VAT product posting group.
        ExpenseVATSpecification.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseVATSpecification, 1);
        ExpenseVATSpecification.FindFirst();
        Assert.AreEqual(ExpenseVATSpecification.Source::Manual, ExpenseVATSpecification.Source, 'The generated VAT specification must be manual.');
        Assert.AreEqual(VATPostingSetup."VAT Prod. Posting Group", ExpenseVATSpecification."VAT Prod. Posting Group", 'The zero-rated VAT product posting group must be retained.');
        Assert.AreEqual(0, ExpenseVATSpecification."VAT %", 'The VAT specification must remain zero-rated.');
        Assert.AreNearlyEqual(120, ExpenseVATSpecification."VAT Base Amount", 0.01, 'The full expense amount must be retained as the VAT base.');
        Assert.AreEqual(0, ExpenseVATSpecification."VAT Amount", 'The zero-rated VAT amount must be zero.');
    end;

    [Test]
    procedure AgentVATSpecificationAPIAcceptsNonSaaSCaller()
    var
        Expense: Record Expense;
        ExpenseVATSpecification: Record "Expense VAT Specification";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        // [SCENARIO] The Expense VAT Specification API accepts callers outside SaaS for local agent development.
        if EnvironmentInfo.IsSaaSInfrastructure() then
            exit;

        // [GIVEN] A VAT specification whose relational fields have been validated against a persisted expense.
        Initialize();
        CreateAgentVATSpecificationFixture(ExpenseVATSpecification, Expense);

        // [WHEN] A caller attempts to insert an agent-authored VAT specification through the API.
        ExpenseVATSpecification.Insert(true);

        // [THEN] The agent-authored VAT specification is inserted.
        Assert.AreEqual(ExpenseVATSpecification.Source::Agent, ExpenseVATSpecification.Source, 'The VAT specification source must be Agent.');
        Assert.IsTrue(ExpenseVATSpecification.Get(Expense."No.", ExpenseVATSpecification."Line No."), 'The VAT specification must be inserted for the parent expense.');
    end;

    [Test]
    procedure AgentVATSpecificationInsertAcceptsNonSaaSCaller()
    var
        Expense: Record Expense;
        ExpenseVATSpecification: Record "Expense VAT Specification";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        // [SCENARIO] The table authorization subscriber accepts agent-authored VAT specifications outside SaaS.
        if EnvironmentInfo.IsSaaSInfrastructure() then
            exit;

        // [GIVEN] A VAT specification whose relational fields have been validated against a persisted expense.
        Initialize();
        CreateAgentVATSpecificationFixture(ExpenseVATSpecification, Expense);

        // [WHEN] A caller attempts to insert an agent-authored VAT specification with table triggers.
        ExpenseVATSpecification.Insert(true);

        // [THEN] The agent-authored VAT specification is inserted.
        Assert.IsTrue(ExpenseVATSpecification.Get(Expense."No.", ExpenseVATSpecification."Line No."), 'The VAT specification must be inserted for the parent expense.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AgentVATSpecificationCannotBeUpdatedModifiedOrDeleted()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseVATSpecification: Record "Expense VAT Specification";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] Agent-authored VAT specifications cannot be regenerated, modified, or deleted.
        Initialize();

        // [GIVEN] An expense with an Agent-authored VAT specification.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        CreateSubcategoryWithVATRate(ExpenseSubCategory, ExpenseCategory.Code, 20, VATPostingSetup);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', 120);

        ExpenseVATSpecification.SetRange("Expense No.", Expense."No.");
        ExpenseVATSpecification.DeleteAll(false);
        ExpenseVATSpecification.Init();
        ExpenseVATSpecification."Expense No." := Expense."No.";
        ExpenseVATSpecification."Line No." := 1;
        ExpenseVATSpecification.Source := ExpenseVATSpecification.Source::Manual;
        ExpenseVATSpecification."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        ExpenseVATSpecification."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        ExpenseVATSpecification.Amount := 120;
        ExpenseVATSpecification.Insert(true);
        ExpenseVATSpecification.Source := ExpenseVATSpecification.Source::Agent;
        ExpenseVATSpecification.Modify(false);
        Commit();

        // [WHEN] The VAT specification is regenerated, modified, or deleted.
        asserterror Expense.UpdateVATSpecification(Expense."No.");
        Assert.ExpectedError(ModifyOrDeleteAgentVATSpecErr);

        ExpenseVATSpecification.Amount := 121;
        asserterror ExpenseVATSpecification.Modify(true);
        Assert.ExpectedError(ModifyOrDeleteAgentVATSpecErr);

        asserterror ExpenseVATSpecification.Delete(true);
        Assert.ExpectedError(ModifyOrDeleteAgentVATSpecErr);

        // [THEN] The Agent-authored VAT specification remains unchanged.
        ExpenseVATSpecification.Get(Expense."No.", 1);
        Assert.AreEqual(ExpenseVATSpecification.Source::Agent, ExpenseVATSpecification.Source, 'The VAT specification source must remain Agent.');
        Assert.AreEqual(120, ExpenseVATSpecification.Amount, 'The Agent-authored VAT specification must remain unchanged.');
        ExpenseVATSpecification.Delete(false);
    end;

    [Test]
    procedure UpdateVATSpecificationAggregatesItemizationsBySubcategory()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseItemization: array[2] of Record "Expense Itemization";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseVATSpecification: Record "Expense VAT Specification";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] Updating the VAT specification for an itemized expense aggregates equal category and subcategory rows.
        Initialize();

        // [GIVEN] An itemized expense with two amounts in the same 20% VAT subcategory.
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory, ExpenseCategory.Code, 20, VATPostingSetup);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 120);
        LibraryExpense.CreateExpenseItemization(ExpenseItemization[1], Expense, ExpenseCategory.Code, ExpenseSubCategory.Code, WorkDate(), 50, 1);
        LibraryExpense.CreateExpenseItemization(ExpenseItemization[2], Expense, ExpenseCategory.Code, ExpenseSubCategory.Code, WorkDate(), 70, 1);

        // [WHEN] The VAT specification is updated.
        Expense.UpdateVATSpecification(Expense."No.");

        // [THEN] One VAT specification contains the aggregated amount and calculated VAT.
        ExpenseVATSpecification.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseVATSpecification, 1);
        ExpenseVATSpecification.FindFirst();
        Assert.AreEqual(ExpenseCategory.Code, ExpenseVATSpecification."Expense Category", 'The itemization category must be copied.');
        Assert.AreEqual(ExpenseSubCategory.Code, ExpenseVATSpecification."Expense Subcategory", 'The itemization subcategory must be copied.');
        Assert.AreNearlyEqual(120, ExpenseVATSpecification.Amount, 0.01, 'Itemization amounts must be aggregated.');
        Assert.AreNearlyEqual(100, ExpenseVATSpecification."VAT Base Amount", 0.01, 'VAT base must be calculated from the aggregated amount.');
        Assert.AreNearlyEqual(20, ExpenseVATSpecification."VAT Amount", 0.01, 'VAT must be calculated from the aggregated amount.');
    end;

    local procedure VerifyPartialVATReclaimPosting(ReclaimPct: Decimal; ExpectedDeductibleBase: Decimal; ExpectedDeductibleVAT: Decimal; ExpectedNonDeductibleBase: Decimal; ExpectedNonDeductibleVAT: Decimal; ExpectedReclaimVATLCY: Decimal; ExpectedReclaimVATRCY: Decimal)
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[4] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        Vendor: Record Vendor;
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
    begin
        Initialize();

        // [GIVEN] A 120 LCY expense with 20% VAT and a report reimbursed at 2 RCY per LCY.
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 20, VATPostingSetup[1]);
        VATPostingSetup[1].Validate("Allow Non-Deductible VAT", VATPostingSetup[1]."Allow Non-Deductible VAT"::Allow);
        VATPostingSetup[1].Validate("Non-Ded. Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup[1].Modify(true);
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 120, 0, 0, 0);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 2, 2);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");

        // [GIVEN] The VAT specification is approved with partial reclaim.
        LibraryPurchase.CreateVendor(Vendor);
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.FindFirst();
        ExpenseReportLine.Validate("Vendor No.", Vendor."No.");
        ExpenseReportLine.Modify(true);
        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        ExpenseReportLineVATSpec.FindFirst();
        ExpenseReportLineVATSpec.Validate("Reclaim %", ReclaimPct);
        ExpenseReportLineVATSpec.Validate("Reclaim Status", ExpenseReportLineVATSpec."Reclaim Status"::Approved);
        ExpenseReportLineVATSpec.Modify(true);

        // [WHEN] The expense report is posted.
        ExpenseReportHeader.PerformManualRelease();
        PostExpenseReportWithConfirmation(ExpenseReportPost, ExpenseReportHeader);

        // [THEN] The posted specification retains the partial reclaim amounts in LCY and reimbursement currency.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        PostedExpenseReportLineVATSpec.SetRange("Expense Report No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportLineVATSpec.SetFilter("Expense Report Line No.", '<>%1', 0);
        PostedExpenseReportLineVATSpec.FindFirst();
        Assert.AreNearlyEqual(ReclaimPct, PostedExpenseReportLineVATSpec."Reclaim %", 0.01, 'The posted VAT specification must retain the partial reclaim percentage.');
        Assert.AreNearlyEqual(ExpectedReclaimVATLCY, PostedExpenseReportLineVATSpec."Reclaim VAT Amount (LCY)", 0.01, 'The posted reclaim VAT amount in LCY must match the partial reclaim percentage.');
        Assert.AreNearlyEqual(ExpectedReclaimVATRCY, PostedExpenseReportLineVATSpec."Reclaim VAT Amount (RCY)", 0.01, 'The posted reclaim VAT amount in reimbursement currency must match the partial reclaim percentage.');

        // [THEN] The VAT entry contains distinct deductible and non-deductible portions.
        VATEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup[1]."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup[1]."VAT Prod. Posting Group");
        VATEntry.CalcSums(Base, Amount, "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        Assert.AreNearlyEqual(ExpectedDeductibleBase, VATEntry.Base, 0.01, 'The VAT entry must contain the deductible VAT base.');
        Assert.AreNearlyEqual(ExpectedDeductibleVAT, VATEntry.Amount, 0.01, 'The VAT entry must contain the deductible VAT amount.');
        Assert.AreNearlyEqual(ExpectedNonDeductibleBase, VATEntry."Non-Deductible VAT Base", 0.01, 'The VAT entry must contain the non-deductible VAT base.');
        Assert.AreNearlyEqual(ExpectedNonDeductibleVAT, VATEntry."Non-Deductible VAT Amount", 0.01, 'The VAT entry must contain the non-deductible VAT amount.');

        // [THEN] The non-deductible VAT amount is routed to its configured purchase VAT account.
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.SetRange("G/L Account No.", VATPostingSetup[1]."Non-Ded. Purchase VAT Account");
        GLEntry.CalcSums(Amount);
        Assert.AreNearlyEqual(ExpectedNonDeductibleVAT, GLEntry.Amount, 0.01, 'The non-deductible purchase VAT account must receive the non-reclaimable VAT amount.');
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Posting VAT Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Posting VAT Test");

        ExpenseAgentSetup.Get();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        ExpenseAgentSetup.Validate("Default VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        ExpenseAgentSetup.Modify(true);

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryERMCountryData.UpdateLocalData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        LibraryExpense.UpdateUseRulesInAgentSetup(false);
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Posting VAT Test");
    end;

    local procedure CreateExpenseUserAndCategory(var ExpenseUser: Record "Expense User"; var ExpenseCategory: Record "Expense Category")
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Itemize);
    end;

    local procedure CreateSubcategoryWithVATRate(var ExpenseSubCategory: Record "Expense Subcategory"; CategoryCode: Code[20]; VATRate: Decimal; var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.TestField("Default VAT Bus. Posting Group");
        if VATPostingSetup."VAT Prod. Posting Group" = '' then begin
            LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, ExpenseAgentSetup."Default VAT Bus. Posting Group", VATProductPostingGroup.Code);

            if VATPostingSetup."VAT Identifier" = '' then
                VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
            VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
            VATPostingSetup.Validate("VAT %", VATRate);
            VATPostingSetup.Modify(true);
        end;

        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, CategoryCode, true);
        ExpenseSubCategory.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ExpenseSubCategory.Validate("Default VAT %", VATRate);
        ExpenseSubCategory.Modify(true);
    end;

    local procedure CreateExpenseWithItemizations(var Expense: Record Expense; ExpenseUser: Record "Expense User"; ExpenseCategory: Record "Expense Category"; ExpenseSubCategory: array[4] of Record "Expense Subcategory"; VATPostingSetup: array[3] of Record "VAT Posting Setup")
    var
        ExpenseItemization: array[4] of Record "Expense Itemization";
    begin
        CreateExpenseForHotel(Expense, ExpenseUser, ExpenseCategory, VATPostingSetup[1], 160);

        LibraryExpense.CreateExpenseItemization(ExpenseItemization[1], Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, WorkDate(), 100, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, 100);

        LibraryExpense.CreateExpenseItemization(ExpenseItemization[2], Expense, ExpenseCategory.Code, ExpenseSubCategory[2].Code, WorkDate(), 20, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[2].Code, 20);

        LibraryExpense.CreateExpenseItemization(ExpenseItemization[3], Expense, ExpenseCategory.Code, ExpenseSubCategory[3].Code, WorkDate(), 30, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[3].Code, 30);

        LibraryExpense.CreateExpenseItemization(ExpenseItemization[4], Expense, ExpenseCategory.Code, ExpenseSubCategory[4].Code, WorkDate(), 10, 1);
        CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[4].Code, 10);

        ReleaseExpenseAndUpdateAccounts(Expense, ExpenseUser);
    end;

    local procedure CreateExpenseWithHotelItemizations(var Expense: Record Expense; ExpenseUser: Record "Expense User"; ExpenseCategory: Record "Expense Category"; ExpenseSubCategory: array[4] of Record "Expense Subcategory"; VATPostingSetup: array[3] of Record "VAT Posting Setup"; Amount1: Decimal; Amount2: Decimal; Amount3: Decimal; Amount4: Decimal)
    var
        ExpenseItemization: array[4] of Record "Expense Itemization";
    begin
        CreateExpenseForHotel(Expense, ExpenseUser, ExpenseCategory, VATPostingSetup[1], Amount1 + Amount2 + Amount3 + Amount4);

        if Amount1 <> 0 then begin
            LibraryExpense.CreateExpenseItemization(ExpenseItemization[1], Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, WorkDate(), Amount1, 1);
            CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[1].Code, Amount1);
        end;
        if Amount2 <> 0 then begin
            LibraryExpense.CreateExpenseItemization(ExpenseItemization[2], Expense, ExpenseCategory.Code, ExpenseSubCategory[2].Code, WorkDate(), Amount2, 1);
            CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[2].Code, Amount2);
        end;
        if Amount3 <> 0 then begin
            LibraryExpense.CreateExpenseItemization(ExpenseItemization[3], Expense, ExpenseCategory.Code, ExpenseSubCategory[3].Code, WorkDate(), Amount3, 1);
            CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[3].Code, Amount3);
        end;
        if Amount4 <> 0 then begin
            LibraryExpense.CreateExpenseItemization(ExpenseItemization[4], Expense, ExpenseCategory.Code, ExpenseSubCategory[4].Code, WorkDate(), Amount4, 1);
            CreateExpenseVATSpecification(Expense, ExpenseCategory.Code, ExpenseSubCategory[4].Code, Amount4);
        end;

        ReleaseExpenseAndUpdateAccounts(Expense, ExpenseUser);
    end;

    local procedure CreateExpenseForHotel(var Expense: Record Expense; ExpenseUser: Record "Expense User"; ExpenseCategory: Record "Expense Category"; VATPostingSetup: Record "VAT Posting Setup"; TotalAmount: Decimal)
    var
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        ExpenseSubCategory.SetRange("Expense Category Code", ExpenseCategory.Code);
        if not ExpenseSubCategory.FindFirst() then
            LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', TotalAmount);
        Expense.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Expense.Modify(true);

        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpenseCategory."Reimbursement Type");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify(true);
    end;

    local procedure ReleaseExpenseAndUpdateAccounts(var Expense: Record Expense; ExpenseUser: Record "Expense User")
    var
        Employee: Record Employee;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
    end;

    local procedure PostExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; Expense: Record Expense; ExpenseUser: Record "Expense User")
    var
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();
        PostExpenseReportWithConfirmation(ExpenseReportPost, ExpenseReportHeader);
    end;

    local procedure FindPostedExpenseReport(var PostedExpenseReportHeader: Record "Posted Expense Report Header"; Expense: Record Expense)
    begin
        PostedExpenseReportHeader.SetRange("Expense User No.", Expense."Expense User No.");
        PostedExpenseReportHeader.FindFirst();
    end;

    local procedure AddExpensesToReport(var CreateExpenseReport: Codeunit "Create Expense Report"; ExpenseReportHeader: Record "Expense Report Header"; ExpenseNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ExpenseNo);
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure PostExpenseReportWithConfirmation(var ExpenseReportPost: Codeunit "Expense Report-Post"; var ExpenseReportHeader: Record "Expense Report Header")
    begin
        LibraryVariableStorage.Enqueue(ExpenseReportHeader."No.");
        LibraryVariableStorage.Enqueue(true);
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure GetRefundableDebitAccount(ExpenseCategoryCode: Code[20]): Code[20]
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        ExpenseCategory.Get(ExpenseCategoryCode);
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        exit(ExpensePostingGroup."Refundable Debit Account");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; AccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.CalcSums(Amount);
        Assert.AreNearlyEqual(ExpectedAmount, GLEntry.Amount, 0.01, StrSubstNo(ValueMustBeEqualErr, GLEntry.FieldCaption(Amount), ExpectedAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryWithVAT(DocumentNo: Code[20]; AccountNo: Code[20]; ExpectedAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.CalcSums(Amount, "VAT Amount");
        Assert.AreNearlyEqual(ExpectedAmount, GLEntry.Amount, 0.01, StrSubstNo(ValueMustBeEqualErr, GLEntry.FieldCaption(Amount), ExpectedAmount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(ExpectedVATAmount, GLEntry."VAT Amount", 0.01, StrSubstNo(ValueMustBeEqualErr, GLEntry.FieldCaption("VAT Amount"), ExpectedVATAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyPostedItemizationLine(ExpenseReportNo: Code[20]; SubcategoryCode: Code[20]; ExpectedAmount: Decimal)
    var
        PostedExpenseReportLineItem: Record "Posted Exp. Rep. Line Item";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
    begin
        PostedExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportNo);
        if PostedExpenseReportLineItem.FindSet() then
            repeat
                if PostedExpenseReportLineItem."Expense Subcategory Code" = SubcategoryCode then
                    Assert.AreNearlyEqual(ExpectedAmount, PostedExpenseReportLineItem.Amount, 0.01, StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineItem.FieldCaption(Amount), ExpectedAmount, PostedExpenseReportLineItem.TableCaption()));
            until PostedExpenseReportLineItem.Next() = 0;
    end;

    local procedure VerifyPostedItemizationLineWithDate(ExpenseReportNo: Code[20]; SubcategoryCode: Code[20]; ExpectedDate: Date; ExpectedAmount: Decimal)
    var
        PostedExpenseReportLineItem: Record "Posted Exp. Rep. Line Item";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
    begin
        PostedExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportNo);
        if PostedExpenseReportLineItem.FindSet() then
            repeat
                if (PostedExpenseReportLineItem."Expense Subcategory Code" = SubcategoryCode) and
                   (PostedExpenseReportLineItem."Start Date" = ExpectedDate) then
                    Assert.AreNearlyEqual(ExpectedAmount, PostedExpenseReportLineItem.Amount, 0.01, StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineItem.FieldCaption(Amount), ExpectedAmount, PostedExpenseReportLineItem.TableCaption()));
            until PostedExpenseReportLineItem.Next() = 0;
    end;

    local procedure VerifyPostedItemizationTotal(ExpenseReportNo: Code[20]; ExpectedTotal: Decimal)
    var
        PostedExpenseReportLineItem: Record "Posted Exp. Rep. Line Item";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
    begin
        PostedExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportNo);
        PostedExpenseReportLineItem.CalcSums(Amount);
        Assert.AreNearlyEqual(ExpectedTotal, PostedExpenseReportLineItem.Amount, 0.01, StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineItem.FieldCaption(Amount), ExpectedTotal, PostedExpenseReportLineItem.TableCaption()));
    end;

    local procedure VerifyVATEntryByPostingGroup(DocumentNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.CalcSums(Base, Amount);
        Assert.AreNearlyEqual(ExpectedBase, VATEntry.Base, 0.01, StrSubstNo(ValueMustBeEqualErr, VATEntry.FieldCaption(Base), ExpectedBase, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(ExpectedAmount, VATEntry.Amount, 0.01, StrSubstNo(ValueMustBeEqualErr, VATEntry.FieldCaption(Amount), ExpectedAmount, VATEntry.TableCaption()));
    end;

    local procedure CreateExpenseVATSpecification(Expense: Record Expense; ExpenseCategoryCode: Code[20]; ExpenseSubcategoryCode: Code[20]; Amount: Decimal)
    var
        ExpenseVATSpecification: Record "Expense VAT Specification";
        ExpenseSubcategory: Record "Expense Subcategory";
        RecordRef: RecordRef;
    begin
        ExpenseVATSpecification.Init();
        ExpenseVATSpecification.Source := ExpenseVATSpecification.Source::Manual;
        ExpenseVATSpecification.Validate("Expense No.", Expense."No.");
        RecordRef.GetTable(ExpenseVATSpecification);
        ExpenseVATSpecification.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseVATSpecification.FieldNo("Line No.")));
        ExpenseVATSpecification.Validate("VAT Bus. Posting Group", Expense."VAT Bus. Posting Group");
        ExpenseVATSpecification.Validate("Expense Category", ExpenseCategoryCode);
        ExpenseVATSpecification.Validate("Expense Subcategory", ExpenseSubcategoryCode);
        if ExpenseSubcategoryCode <> '' then begin
            ExpenseSubcategory.Get(ExpenseCategoryCode, ExpenseSubcategoryCode);
            ExpenseVATSpecification.Validate("VAT Prod. Posting Group", ExpenseSubcategory."VAT Prod. Posting Group");
        end;
        ExpenseVATSpecification.Validate(Amount, Amount);
        ExpenseVATSpecification.Insert(true);
    end;

    local procedure CreateAgentVATSpecificationFixture(var ExpenseVATSpecification: Record "Expense VAT Specification"; var Expense: Record Expense)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        CreateSubcategoryWithVATRate(ExpenseSubcategory, ExpenseCategory.Code, 20, VATPostingSetup);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubcategory.Code, '', true, '', 120);
        Expense.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Expense.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Expense.Modify(true);

        ExpenseVATSpecification.Init();
        ExpenseVATSpecification.Validate("Expense No.", Expense."No.");
        ExpenseVATSpecification.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseVATSpecification.Validate("Expense Subcategory", ExpenseSubcategory.Code);
        ExpenseVATSpecification.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        ExpenseVATSpecification.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ExpenseVATSpecification.Validate(Amount, Expense.Amount);
    end;

    local procedure UpdateExpenseReportLinesWithVendor(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        if ExpenseReportLine.FindSet() then
            repeat
                ExpenseReportLine.Validate("Vendor No.", Vendor."No.");
                ExpenseReportLine.Modify(true);
                ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportHeader."No.");
                ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
                if ExpenseReportLineVATSpec.FindSet() then
                    repeat
                        ExpenseReportLineVATSpec.Validate("Reclaim %", 100);
                        ExpenseReportLineVATSpec.Validate("Reclaim Status", ExpenseReportLineVATSpec."Reclaim Status"::Approved);
                        ExpenseReportLineVATSpec.Modify(true);
                    until ExpenseReportLineVATSpec.Next() = 0;
            until ExpenseReportLine.Next() = 0;
    end;

    local procedure UpdateExpenseReportVATSpecLineStatuses(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        Vendor: Record Vendor;
        LineIndex: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        if ExpenseReportLine.FindSet() then
            repeat
                ExpenseReportLine.Validate("Vendor No.", Vendor."No.");
                ExpenseReportLine.Modify(true);
                ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportHeader."No.");
                ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
                if ExpenseReportLineVATSpec.FindSet() then begin
                    LineIndex := 0;
                    repeat
                        ExpenseReportLineVATSpec.Validate("Reclaim %", 100);
                        LineIndex += 1;
                        case LineIndex of
                            1:
                                // First spec line (subcategory 1): Approved
                                ExpenseReportLineVATSpec.Validate("Reclaim Status", ExpenseReportLineVATSpec."Reclaim Status"::Approved);
                            2:
                                // Second spec line (subcategory 2): Rejected
                                ExpenseReportLineVATSpec.Validate("Reclaim Status", ExpenseReportLineVATSpec."Reclaim Status"::Rejected);
                            3:
                                // Third spec line (subcategory 3): Approved
                                ExpenseReportLineVATSpec.Validate("Reclaim Status", ExpenseReportLineVATSpec."Reclaim Status"::Approved);
                            else
                                ExpenseReportLineVATSpec.Validate("Reclaim Status", ExpenseReportLineVATSpec."Reclaim Status"::Approved);
                        end;
                        ExpenseReportLineVATSpec.Modify(true);
                    until ExpenseReportLineVATSpec.Next() = 0;
                end;
            until ExpenseReportLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportStatsPageCalculations()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO] Expense Report Stats page calculates and displays amounts correctly
        Initialize();

        // [GIVEN] Employee "E" and HOTEL category with 2 subcategories at different VAT rates (10%, 20%)
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 20, VATPostingSetup[2]);

        // [GIVEN] Expense "EXP" with itemizations: subcategory[1] for 100, subcategory[2] for 50
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 100, 50, 0, 0);

        // [GIVEN] Expense report is created with expenses added
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        AddExpensesToReport(CreateExpenseReport, ExpenseReportHeader, Expense."No.");
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Calculate fields on expense report header
        ExpenseReportHeader.CalcFields(
            "Amount (LCY)", "Amount without VAT (LCY)", "VAT Amount (LCY)",
            "Reimbursable Amount (LCY)", "Refundable Amount (LCY)", "Approved Reclaim VAT (LCY)");

        // [THEN] Stats page should display calculated amounts
        Assert.AreNotEqual(0, ExpenseReportHeader."Amount (LCY)", 'Total amount should be populated');
        Assert.AreNotEqual(0, ExpenseReportHeader."Amount without VAT (LCY)", 'Amount without VAT should be populated');
        Assert.IsTrue(ExpenseReportHeader."VAT Amount (LCY)" >= 0, 'VAT Amount should be non-negative');
        Assert.AreNotEqual(0, ExpenseReportHeader."Reimbursable Amount (LCY)", 'Reimbursable amount should be populated');
        Assert.AreNotEqual(0, ExpenseReportHeader."Refundable Amount (LCY)", 'Refundable amount should be populated');
        Assert.AreNearlyEqual(17.42, ExpenseReportHeader."Approved Reclaim VAT (LCY)", 0.01, 'Approved Reclaim VAT must match expected VAT total for approved spec lines.');
        Assert.IsTrue(ExpenseReportHeader."Amount (LCY)" = ExpenseReportHeader."Amount without VAT (LCY)" + ExpenseReportHeader."VAT Amount (LCY)", 'Amount should equal Amount without VAT plus VAT Amount');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostedExpenseReportStatsPageCalculations()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
    begin
        // [SCENARIO] Posted Expense Report Stats page calculates and displays amounts correctly
        Initialize();

        // [GIVEN] Employee "E" and HOTEL category with 2 subcategories at different VAT rates (10%, 20%)
        CreateExpenseUserAndCategory(ExpenseUser, ExpenseCategory);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[1], ExpenseCategory.Code, 10, VATPostingSetup[1]);
        CreateSubcategoryWithVATRate(ExpenseSubCategory[2], ExpenseCategory.Code, 20, VATPostingSetup[2]);

        // [GIVEN] Expense "EXP" with itemizations: subcategory[1] for 100, subcategory[2] for 50
        CreateExpenseWithHotelItemizations(Expense, ExpenseUser, ExpenseCategory, ExpenseSubCategory, VATPostingSetup, 100, 50, 0, 0);

        // [GIVEN] Expense report is created and posted
        PostExpenseReport(ExpenseReportHeader, Expense, ExpenseUser);
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);

        // [WHEN] Calculate fields on posted expense report header
        PostedExpenseReportHeader.CalcFields(
            "Amount (LCY)", "Amount without VAT (LCY)", "VAT Amount (LCY)",
            "Reimbursable Amount (LCY)", "Refundable Amount (LCY)", "Approved Reclaim VAT (LCY)");

        // [THEN] Posted Stats page should display calculated amounts
        Assert.AreNotEqual(0, PostedExpenseReportHeader."Amount (LCY)", 'Total amount should be populated');
        Assert.AreNotEqual(0, PostedExpenseReportHeader."Amount without VAT (LCY)", 'Amount without VAT should be populated');
        Assert.IsTrue(PostedExpenseReportHeader."VAT Amount (LCY)" >= 0, 'VAT Amount should be non-negative');
        Assert.AreNotEqual(0, PostedExpenseReportHeader."Reimbursable Amount (LCY)", 'Reimbursable amount should be populated');
        Assert.AreNotEqual(0, PostedExpenseReportHeader."Refundable Amount (LCY)", 'Refundable amount should be populated');
        Assert.AreNearlyEqual(17.42, PostedExpenseReportHeader."Approved Reclaim VAT (LCY)", 0.01, 'Approved Reclaim VAT must match expected VAT total for approved spec lines.');
        Assert.IsTrue(PostedExpenseReportHeader."Amount (LCY)" = PostedExpenseReportHeader."Amount without VAT (LCY)" + PostedExpenseReportHeader."VAT Amount (LCY)", 'Amount should equal Amount without VAT plus VAT Amount');
    end;

    local procedure UpdateExpenseReportLinesWithVendorKeepingPending(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        if ExpenseReportLine.FindSet() then
            repeat
                ExpenseReportLine.Validate("Vendor No.", Vendor."No.");
                ExpenseReportLine.Modify(true);

                ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportHeader."No.");
                ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
                if ExpenseReportLineVATSpec.FindSet() then
                    repeat
                        ExpenseReportLineVATSpec.Validate("Reclaim %", 100);
                        ExpenseReportLineVATSpec.Validate("Reclaim Status", ExpenseReportLineVATSpec."Reclaim Status"::"Pending");
                        ExpenseReportLineVATSpec.Modify(true);
                    until ExpenseReportLineVATSpec.Next() = 0;
            until ExpenseReportLine.Next() = 0;
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        Expenses.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}
