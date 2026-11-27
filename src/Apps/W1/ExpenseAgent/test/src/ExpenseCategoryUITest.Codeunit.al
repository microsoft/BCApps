// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.VAT.Setup;

codeunit 148369 "Expense Category UI Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Expense Category] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure ExpenseCategoryCardCanEditVATDefaultsWhenReclaimEnabled()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseCategory: Record "Expense Category";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        ExpenseCategoryCard: TestPage "Expense Category Card";
    begin
        // [SCENARIO] Category VAT defaults can be maintained on the card when VAT reclaim is enabled.
        Initialize();

        // [GIVEN] VAT reclaim is enabled and a category has no VAT defaults.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Allow VAT Reclaim", true);
        ExpenseAgentSetup.Modify(true);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);

        // [WHEN] The category VAT defaults are edited on the card.
        ExpenseCategoryCard.OpenEdit();
        ExpenseCategoryCard.GoToRecord(ExpenseCategory);
        Assert.IsTrue(ExpenseCategoryCard."VAT Prod. Posting Group".Visible(), 'The category VAT posting group must be visible.');
        Assert.IsTrue(ExpenseCategoryCard."Default VAT %".Visible(), 'The default VAT percentage must be visible.');
        Assert.IsTrue(ExpenseCategoryCard."Default VAT Reclaim %".Visible(), 'The default VAT reclaim percentage must be visible.');
        ExpenseCategoryCard."VAT Prod. Posting Group".SetValue(VATProductPostingGroup.Code);
        ExpenseCategoryCard."Default VAT %".SetValue(20);
        ExpenseCategoryCard."Default VAT Reclaim %".SetValue(50);
        ExpenseCategoryCard.Close();

        // [THEN] All three VAT defaults are saved on the category.
        ExpenseCategory.Get(ExpenseCategory.Code);
        ExpenseCategory.TestField("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        ExpenseCategory.TestField("Default VAT %", 20);
        ExpenseCategory.TestField("Default VAT Reclaim %", 50);
    end;

    [Test]
    procedure ExpenseCategoryCardHidesVATDefaultsWhenReclaimDisabled()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseCategory: Record "Expense Category";
        ExpenseCategoryCard: TestPage "Expense Category Card";
    begin
        // [SCENARIO] Category VAT defaults are hidden when VAT reclaim is disabled.
        Initialize();

        // [GIVEN] VAT reclaim is disabled.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Allow VAT Reclaim", false);
        ExpenseAgentSetup.Modify(true);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [WHEN] The expense category card is opened.
        ExpenseCategoryCard.OpenEdit();
        ExpenseCategoryCard.GoToRecord(ExpenseCategory);

        // [THEN] None of the VAT defaults are shown.
        Assert.IsFalse(ExpenseCategoryCard."VAT Prod. Posting Group".Visible(), 'The category VAT posting group must be hidden.');
        Assert.IsFalse(ExpenseCategoryCard."Default VAT %".Visible(), 'The default VAT percentage must be hidden.');
        Assert.IsFalse(ExpenseCategoryCard."Default VAT Reclaim %".Visible(), 'The default VAT reclaim percentage must be hidden.');
        ExpenseCategoryCard.Close();
    end;

    [Test]
    procedure PostingGroupUsedBySubcategoryCannotBeDeleted()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseSubcategories: TestPage "Expense Subcategories";
    begin
        // [SCENARIO] A posting group referenced by an expense subcategory cannot be deleted.
        Initialize();

        // [GIVEN] A posting group is assigned to an expense subcategory through the subcategories page.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Itemize);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpensePostingGroup(ExpensePostingGroup);

        ExpenseSubcategories.OpenEdit();
        ExpenseSubcategories.GoToRecord(ExpenseSubcategory);
        ExpenseSubcategories."Posting Group".SetValue(ExpensePostingGroup.Code);
        ExpenseSubcategories.Close();

        // [WHEN] The referenced posting group is deleted.
        asserterror ExpensePostingGroup.Delete(true);

        // [THEN] Deletion is blocked because the posting group is used by an expense subcategory.
        Assert.ExpectedError('Expense Subcategory');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Category UI Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        LibraryExpense.UpdateVATBusinessPostingGroupInAgentSetup();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Category UI Test");
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryERMCountryData.UpdateLocalData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        LibraryExpense.UpdateUseRulesInAgentSetup(false);
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Category UI Test");
    end;
}
