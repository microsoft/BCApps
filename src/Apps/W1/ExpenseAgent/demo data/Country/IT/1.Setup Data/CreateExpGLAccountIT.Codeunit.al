// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 8424 "Create Exp. GL Account IT"
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
        ContosoGLAccount.InsertGLAccount(EmployeeAdvancesPrepayments(), EmployeeAdvancesPrepaymentsName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetCash(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpenseReimbursementPayable(), EmployeeExpenseReimbursementPayableName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CorporateCardExpenseClearing(), CorporateCardExpenseClearingName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CompanyPaidExpenseClearing(), CompanyPaidExpenseClearingName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetTravelExpense(), 80);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowance(), PerDiemAllowanceName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CarRentalExpenses(), CarRentalExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Income, 80);
        ContosoGLAccount.InsertGLAccount(NonDeductibleEmployeeExpenses(), NonDeductibleEmployeeExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(EmployeeAdvancesPrepaymentsName(), '2341');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpenseReimbursementPayableName(), '5851');
        ContosoGLAccount.AddAccountForLocalization(CorporateCardExpenseClearingName(), '5852');
        ContosoGLAccount.AddAccountForLocalization(CompanyPaidExpenseClearingName(), '5853');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceName(), '8431');
        ContosoGLAccount.AddAccountForLocalization(CarRentalExpensesName(), '8432');
        ContosoGLAccount.AddAccountForLocalization(NonDeductibleEmployeeExpensesName(), '8911');
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        EmployeeAdvancesPrepaymentsTok: Label 'Employee Advances and Expense Prepayments', MaxLength = 100;
        EmployeeExpenseReimbursementPayableTok: Label 'Employee Expense Reimbursement Payable', MaxLength = 100;
        CorporateCardExpenseClearingTok: Label 'Corporate Card Expense Clearing', MaxLength = 100;
        CompanyPaidExpenseClearingTok: Label 'Company-Paid Expense Clearing', MaxLength = 100;
        PerDiemAllowanceTok: Label 'Per Diem Allowance', MaxLength = 100;
        CarRentalExpensesTok: Label 'Car Rental Expenses', MaxLength = 100;
        NonDeductibleEmployeeExpensesTok: Label 'Non-Deductible Employee Expenses', MaxLength = 100;

    procedure EmployeeAdvancesPrepayments(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeAdvancesPrepaymentsName()));
    end;

    procedure EmployeeAdvancesPrepaymentsName(): Text[100]
    begin
        exit(EmployeeAdvancesPrepaymentsTok);
    end;

    procedure EmployeeExpenseReimbursementPayable(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpenseReimbursementPayableName()));
    end;

    procedure EmployeeExpenseReimbursementPayableName(): Text[100]
    begin
        exit(EmployeeExpenseReimbursementPayableTok);
    end;

    procedure CorporateCardExpenseClearing(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CorporateCardExpenseClearingName()));
    end;

    procedure CorporateCardExpenseClearingName(): Text[100]
    begin
        exit(CorporateCardExpenseClearingTok);
    end;

    procedure CompanyPaidExpenseClearing(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyPaidExpenseClearingName()));
    end;

    procedure CompanyPaidExpenseClearingName(): Text[100]
    begin
        exit(CompanyPaidExpenseClearingTok);
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

    procedure NonDeductibleEmployeeExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(NonDeductibleEmployeeExpensesName()));
    end;

    procedure NonDeductibleEmployeeExpensesName(): Text[100]
    begin
        exit(NonDeductibleEmployeeExpensesTok);
    end;
}
