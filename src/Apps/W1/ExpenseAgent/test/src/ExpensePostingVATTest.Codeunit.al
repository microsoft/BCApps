// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;

codeunit 148330 "Expense Posting VAT Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        NotApprovedForVATReclaimErr: Label 'VAT Reclaim Status is not set for Line with Expense Category %1 and Expense Subcategory %2.', Comment = '%1 = Expense Category, %2 = Expense Subcategory';

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
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);
        UpdateExpenseReportVATSpecLineStatuses(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Expense report is posted
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

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
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        UpdateExpenseReportLinesWithVendorKeepingPending(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Posting is attempted
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] A reclaim-status error is raised and posting does not create a posted report.
        Assert.ExpectedError(StrSubstNo(NotApprovedForVATReclaimErr, ExpenseCategory.Code, ExpenseSubCategory[1].Code));
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordCount(PostedExpenseReportHeader, 0);
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATSetup: Record "VAT Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
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

        VATSetup.Get();
        VATSetup.Validate("Non-Deductible VAT Is Enabled", true);
        VATSetup.Modify(true);

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
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
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        UpdateExpenseReportLinesWithVendor(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
    end;

    local procedure FindPostedExpenseReport(var PostedExpenseReportHeader: Record "Posted Expense Report Header"; Expense: Record Expense)
    begin
        PostedExpenseReportHeader.SetRange("Expense User No.", Expense."Expense User No.");
        PostedExpenseReportHeader.FindFirst();
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
        RecordRef: RecordRef;
    begin
        ExpenseVATSpecification.Init();
        ExpenseVATSpecification.Validate("Expense No.", Expense."No.");
        RecordRef.GetTable(ExpenseVATSpecification);
        ExpenseVATSpecification.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseVATSpecification.FieldNo("Line No.")));
        ExpenseVATSpecification.Validate("VAT Bus. Posting Group", Expense."VAT Bus. Posting Group");
        ExpenseVATSpecification.Validate("Expense Category", ExpenseCategoryCode);
        ExpenseVATSpecification.Validate("Expense Subcategory", ExpenseSubcategoryCode);
        ExpenseVATSpecification.Validate(Amount, Amount);
        ExpenseVATSpecification.Insert(true);
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
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
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
        Expenses.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
