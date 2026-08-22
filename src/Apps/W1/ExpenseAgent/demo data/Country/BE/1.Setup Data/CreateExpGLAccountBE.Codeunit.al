// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 8413 "Create Exp. GL Account BE"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense G/L Account", 'OnAfterAddGLAccountsForLocalization', '', false, false)]
    local procedure ModifyGLAccount()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        SubCategory: Text[80];
    begin
        AddGLAccounts();

        SubCategory := Format(GLAccountCategoryMgt.GetPrepaidExpenses(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeTravelAdvances(), EmployeeTravelAdvancesName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetCash(), 80);
        ContosoGLAccount.InsertGLAccount(CompanyPaidExpenseClearing(), CompanyPaidExpenseClearingName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CorporateCardExpenseClearing(), CorporateCardExpenseClearingName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetTravelExpense(), 80);
        ContosoGLAccount.InsertGLAccount(BusinessMeals(), BusinessMealsName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(MileageAllowance(), MileageAllowanceName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowance(), PerDiemAllowanceName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        ContosoGLAccount.InsertGLAccount(OtherEmployeeExpenses(), OtherEmployeeExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Income, 80);
        ContosoGLAccount.InsertGLAccount(NonRefundableEmployeeExpenses(), NonRefundableEmployeeExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseRoundingDifferences(), ExpenseRoundingDifferencesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(EmployeeTravelAdvancesName(), '416000');
        ContosoGLAccount.AddAccountForLocalization(CompanyPaidExpenseClearingName(), '457100');
        ContosoGLAccount.AddAccountForLocalization(CorporateCardExpenseClearingName(), '457200');
        ContosoGLAccount.AddAccountForLocalization(BusinessMealsName(), '613910');
        ContosoGLAccount.AddAccountForLocalization(MileageAllowanceName(), '613940');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceName(), '613950');
        ContosoGLAccount.AddAccountForLocalization(OtherEmployeeExpensesName(), '623100');
        ContosoGLAccount.AddAccountForLocalization(NonRefundableEmployeeExpensesName(), '643100');
        ContosoGLAccount.AddAccountForLocalization(ExpenseRoundingDifferencesName(), '655100');
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        EmployeeTravelAdvancesTok: Label 'Employee Travel Advances', MaxLength = 100;
        CompanyPaidExpenseClearingTok: Label 'Company Paid Expense Clearing', MaxLength = 100;
        CorporateCardExpenseClearingTok: Label 'Corporate Card Expense Clearing', MaxLength = 100;
        BusinessMealsTok: Label 'Business Meals', MaxLength = 100;
        MileageAllowanceTok: Label 'Mileage Allowance', MaxLength = 100;
        PerDiemAllowanceTok: Label 'Per-Diem Allowance', MaxLength = 100;
        OtherEmployeeExpensesTok: Label 'Other Employee Expenses', MaxLength = 100;
        NonRefundableEmployeeExpensesTok: Label 'Non-Refundable Employee Expenses', MaxLength = 100;
        ExpenseRoundingDifferencesTok: Label 'Expense Rounding Differences', MaxLength = 100;

    procedure EmployeeTravelAdvances(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeTravelAdvancesName()));
    end;

    procedure EmployeeTravelAdvancesName(): Text[100]
    begin
        exit(EmployeeTravelAdvancesTok);
    end;

    procedure CompanyPaidExpenseClearing(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyPaidExpenseClearingName()));
    end;

    procedure CompanyPaidExpenseClearingName(): Text[100]
    begin
        exit(CompanyPaidExpenseClearingTok);
    end;

    procedure CorporateCardExpenseClearing(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CorporateCardExpenseClearingName()));
    end;

    procedure CorporateCardExpenseClearingName(): Text[100]
    begin
        exit(CorporateCardExpenseClearingTok);
    end;

    procedure BusinessMeals(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(BusinessMealsName()));
    end;

    procedure BusinessMealsName(): Text[100]
    begin
        exit(BusinessMealsTok);
    end;

    procedure MileageAllowance(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MileageAllowanceName()));
    end;

    procedure MileageAllowanceName(): Text[100]
    begin
        exit(MileageAllowanceTok);
    end;

    procedure PerDiemAllowance(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(PerDiemAllowanceName()));
    end;

    procedure PerDiemAllowanceName(): Text[100]
    begin
        exit(PerDiemAllowanceTok);
    end;

    procedure OtherEmployeeExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherEmployeeExpensesName()));
    end;

    procedure OtherEmployeeExpensesName(): Text[100]
    begin
        exit(OtherEmployeeExpensesTok);
    end;

    procedure NonRefundableEmployeeExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(NonRefundableEmployeeExpensesName()));
    end;

    procedure NonRefundableEmployeeExpensesName(): Text[100]
    begin
        exit(NonRefundableEmployeeExpensesTok);
    end;

    procedure ExpenseRoundingDifferences(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(ExpenseRoundingDifferencesName()));
    end;

    procedure ExpenseRoundingDifferencesName(): Text[100]
    begin
        exit(ExpenseRoundingDifferencesTok);
    end;
}
