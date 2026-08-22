// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 8435 "Create Exp. GL Account CH"
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

        SubCategory := Format(GLAccountCategoryMgt.GetPrepaidExpenses(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpenseAdvances(), EmployeeExpenseAdvancesName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetCash(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpenseReimbursementsPayable(), EmployeeExpenseReimbursementsPayableName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CompanyCardExpensesPayable(), CompanyCardExpensesPayableName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CompanyPaidExpenseClearing(), CompanyPaidExpenseClearingName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetTravelExpense(), 80);
        ContosoGLAccount.InsertGLAccount(MileageAllowance(), MileageAllowanceName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowance(), PerDiemAllowanceName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        ContosoGLAccount.InsertGLAccount(EntertainmentExpenses(), EntertainmentExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(MealsAndHospitalityExpenses(), MealsAndHospitalityExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpenseAdvancesName(), '1305');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpenseReimbursementsPayableName(), '2270');
        ContosoGLAccount.AddAccountForLocalization(CompanyCardExpensesPayableName(), '2271');
        ContosoGLAccount.AddAccountForLocalization(CompanyPaidExpenseClearingName(), '2272');
        ContosoGLAccount.AddAccountForLocalization(MileageAllowanceName(), '5821');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceName(), '5822');
        ContosoGLAccount.AddAccountForLocalization(MealsAndHospitalityExpensesName(), '5841');
        ContosoGLAccount.AddAccountForLocalization(EntertainmentExpensesName(), '5840');
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        EmployeeExpenseAdvancesTok: Label 'Employee Expense Advances', MaxLength = 100;
        EmployeeExpenseReimbursementsPayableTok: Label 'Employee Expense Reimbursements Payable', MaxLength = 100;
        CompanyCardExpensesPayableTok: Label 'Company Card Expenses Payable', MaxLength = 100;
        CompanyPaidExpenseClearingTok: Label 'Company-Paid Expense Clearing', MaxLength = 100;
        MileageAllowanceTok: Label 'Mileage Allowance', MaxLength = 100;
        PerDiemAllowanceTok: Label 'Per Diem Allowance', MaxLength = 100;
        EntertainmentExpensesTok: Label 'Entertainment Expenses', MaxLength = 100;
        MealsAndHospitalityExpensesTok: Label 'Meals and Hospitality Expenses', MaxLength = 100;

    procedure EmployeeExpenseAdvances(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpenseAdvancesName()));
    end;

    procedure EmployeeExpenseAdvancesName(): Text[100]
    begin
        exit(EmployeeExpenseAdvancesTok);
    end;

    procedure EmployeeExpenseReimbursementsPayable(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpenseReimbursementsPayableName()));
    end;

    procedure EmployeeExpenseReimbursementsPayableName(): Text[100]
    begin
        exit(EmployeeExpenseReimbursementsPayableTok);
    end;

    procedure CompanyCardExpensesPayable(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCardExpensesPayableName()));
    end;

    procedure CompanyCardExpensesPayableName(): Text[100]
    begin
        exit(CompanyCardExpensesPayableTok);
    end;

    procedure CompanyPaidExpenseClearing(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyPaidExpenseClearingName()));
    end;

    procedure CompanyPaidExpenseClearingName(): Text[100]
    begin
        exit(CompanyPaidExpenseClearingTok);
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

    procedure EntertainmentExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EntertainmentExpensesName()));
    end;

    procedure EntertainmentExpensesName(): Text[100]
    begin
        exit(EntertainmentExpensesTok);
    end;

    procedure MealsAndHospitalityExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MealsAndHospitalityExpensesName()));
    end;

    procedure MealsAndHospitalityExpensesName(): Text[100]
    begin
        exit(MealsAndHospitalityExpensesTok);
    end;
}
