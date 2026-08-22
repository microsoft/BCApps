// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 8468 "Create Exp. GL Account CZ"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense G/L Account", 'OnAfterAddGLAccountsForLocalization', '', false, false)]
    local procedure ModifyGLAccount()
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        SubCategory: Text[80];
    begin
        AddGLAccounts();

        SubCategory := CopyStr(GLAccountCategoryMgt.GetCash(), 1, MaxStrLen(SubCategory));
        ContosoGLAccount.InsertGLAccount(CompanyCardExpensesPayable(), CompanyCardExpensesPayableName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := CopyStr(GLAccountCategoryMgt.GetPrepaidExpenses(), 1, MaxStrLen(SubCategory));
        ContosoGLAccount.InsertGLAccount(EmployeeExpenseAdvances(), EmployeeExpenseAdvancesName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := TravelExpenseSubcategoryTok;
        ContosoGLAccount.InsertGLAccount(MileageAllowance(), MileageAllowanceName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowance(), PerDiemAllowanceName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CarRentalExpenses(), CarRentalExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(MealsAndHospitalityExpenses(), MealsAndHospitalityExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        SubCategory := IncomeSubcategoryTok;
        ContosoGLAccount.InsertGLAccount(NonRefundableEmployeeExpenses(), NonRefundableEmployeeExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseRoundingDifferences(), ExpenseRoundingDifferencesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCardExpensesPayableName(), '325200');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpenseAdvancesName(), '335100');
        ContosoGLAccount.AddAccountForLocalization(MileageAllowanceName(), '512200');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceName(), '512300');
        ContosoGLAccount.AddAccountForLocalization(CarRentalExpensesName(), '512400');
        ContosoGLAccount.AddAccountForLocalization(MealsAndHospitalityExpensesName(), '513200');
        ContosoGLAccount.AddAccountForLocalization(NonRefundableEmployeeExpensesName(), '548200');
        ContosoGLAccount.AddAccountForLocalization(ExpenseRoundingDifferencesName(), '548900');
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        TravelExpenseSubcategoryTok: Label 'A.3. Services', MaxLength = 80, Locked = true;
        IncomeSubcategoryTok: Label 'III.3. Another Operating Revenues', MaxLength = 80, Locked = true;
        CompanyCardExpensesPayableTok: Label 'Company Card Expenses Payable', MaxLength = 100;
        EmployeeExpenseAdvancesTok: Label 'Employee Expense Advances', MaxLength = 100;
        MileageAllowanceTok: Label 'Mileage Allowance', MaxLength = 100;
        PerDiemAllowanceTok: Label 'Per Diem Allowance', MaxLength = 100;
        CarRentalExpensesTok: Label 'Car Rental Expenses', MaxLength = 100;
        MealsAndHospitalityExpensesTok: Label 'Meals and Hospitality Expenses', MaxLength = 100;
        NonRefundableEmployeeExpensesTok: Label 'Non-Refundable Employee Expenses', MaxLength = 100;
        ExpenseRoundingDifferencesTok: Label 'Expense Rounding Differences', MaxLength = 100;

    procedure CompanyCardExpensesPayable(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCardExpensesPayableName()));
    end;

    procedure CompanyCardExpensesPayableName(): Text[100]
    begin
        exit(CompanyCardExpensesPayableTok);
    end;

    procedure EmployeeExpenseAdvances(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpenseAdvancesName()));
    end;

    procedure EmployeeExpenseAdvancesName(): Text[100]
    begin
        exit(EmployeeExpenseAdvancesTok);
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

    procedure CarRentalExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CarRentalExpensesName()));
    end;

    procedure CarRentalExpensesName(): Text[100]
    begin
        exit(CarRentalExpensesTok);
    end;

    procedure MealsAndHospitalityExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MealsAndHospitalityExpensesName()));
    end;

    procedure MealsAndHospitalityExpensesName(): Text[100]
    begin
        exit(MealsAndHospitalityExpensesTok);
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
