// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 8446 "Create Exp. GL Account NO"
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

        SubCategory := Format(GLAccountCategoryMgt.GetCash(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpensePayableCash(), EmployeeExpensePayableCashName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(EmployeeExpensePayableCard(), EmployeeExpensePayableCardName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(EmployeeExpensePayableCompanyPaid(), EmployeeExpensePayableCompanyPaidName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetPrepaidExpenses(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpensePrepayments(), EmployeeExpensePrepaymentsName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Income, 80);
        ContosoGLAccount.InsertGLAccount(NonRefundableEmployeeExpenses(), NonRefundableEmployeeExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseRoundingDifferences(), ExpenseRoundingDifferencesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpensePayableCashName(), '5960');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpensePayableCardName(), '5961');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpensePayableCompanyPaidName(), '5962');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpensePrepaymentsName(), '5963');
        ContosoGLAccount.AddAccountForLocalization(NonRefundableEmployeeExpensesName(), '5964');
        ContosoGLAccount.AddAccountForLocalization(ExpenseRoundingDifferencesName(), '5965');
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        EmployeeExpensePayableCashTok: Label 'Employee Expense Payable - Cash Reimbursement', MaxLength = 100;
        EmployeeExpensePayableCardTok: Label 'Employee Expense Payable - Company Card', MaxLength = 100;
        EmployeeExpensePayableCompanyPaidTok: Label 'Employee Expense Payable - Company Paid', MaxLength = 100;
        EmployeeExpensePrepaymentsTok: Label 'Employee Expense Prepayments', MaxLength = 100;
        NonRefundableEmployeeExpensesTok: Label 'Non-Refundable Employee Expenses', MaxLength = 100;
        ExpenseRoundingDifferencesTok: Label 'Expense Rounding Differences', MaxLength = 100;

    procedure EmployeeExpensePayableCash(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpensePayableCashName()));
    end;

    procedure EmployeeExpensePayableCashName(): Text[100]
    begin
        exit(EmployeeExpensePayableCashTok);
    end;

    procedure EmployeeExpensePayableCard(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpensePayableCardName()));
    end;

    procedure EmployeeExpensePayableCardName(): Text[100]
    begin
        exit(EmployeeExpensePayableCardTok);
    end;

    procedure EmployeeExpensePayableCompanyPaid(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpensePayableCompanyPaidName()));
    end;

    procedure EmployeeExpensePayableCompanyPaidName(): Text[100]
    begin
        exit(EmployeeExpensePayableCompanyPaidTok);
    end;

    procedure EmployeeExpensePrepayments(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpensePrepaymentsName()));
    end;

    procedure EmployeeExpensePrepaymentsName(): Text[100]
    begin
        exit(EmployeeExpensePrepaymentsTok);
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
