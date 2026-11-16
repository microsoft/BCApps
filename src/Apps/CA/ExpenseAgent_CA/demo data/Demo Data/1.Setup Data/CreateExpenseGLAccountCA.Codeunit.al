#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 27100 "Create Expense G/L Account CA"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';

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
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.BusinessEntertainingNondeductibleAccount(), ExpenseGLAccount.BusinessEntertainingNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherTravelExpensesAccount(), ExpenseGLAccount.OtherTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.CompanyCreditCardsAccountName(), '11160');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsAccountName(), '13600');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsExpensesAccountName(), '13610');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsTotalAccountName(), '13690');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '61310');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '61320');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '61330');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '67410');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), '67420');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), '67430');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.RentalVehiclesAccountName(), '63110');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.BusinessEntertainingNondeductibleAccountName(), '61120');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherTravelExpensesAccountName(), '61340');
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
}
#endif