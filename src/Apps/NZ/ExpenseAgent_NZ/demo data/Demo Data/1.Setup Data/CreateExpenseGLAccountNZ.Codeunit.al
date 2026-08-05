// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 17220 "Create Expense G/L Account NZ"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense G/L Account", 'OnAfterAddGLAccountsForLocalization', '', false, false)]
    local procedure ModifyGLAccount()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccounts();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.CompanyCreditCardsAccount(), ExpenseGLAccount.CompanyCreditCardsAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.EmployeePrepaymentsAccount(), ExpenseGLAccount.EmployeePrepaymentsAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::"Begin-Total", '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', false, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.EmployeePrepaymentsExpensesAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.EmployeePrepaymentsTotalAccount(), ExpenseGLAccount.EmployeePrepaymentsTotalAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::"End-Total", '', '', '', 0, ExpenseGLAccount.EmployeePrepaymentsAccount() + '..' + ExpenseGLAccount.EmployeePrepaymentsTotalAccount(), Enum::"General Posting Type"::" ", '', '', false, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.PerDiemTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.MileageTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesDeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.RentalVehiclesAccount(), ExpenseGLAccount.RentalVehiclesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.CompanyCreditCardsAccountName(), '2950');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsAccountName(), '2500');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsExpensesAccountName(), '2510');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsTotalAccountName(), '2590');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '8431');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '8432');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '8433');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '8421');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), '8650');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), '8660');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.RentalVehiclesAccountName(), '8435');
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
}