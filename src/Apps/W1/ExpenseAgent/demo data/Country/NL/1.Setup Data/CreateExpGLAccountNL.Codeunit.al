// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 8402 "Create Exp. GL Account NL"
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
        ContosoGLAccount.InsertGLAccount(CorporateCardExpensePayable(), CorporateCardExpensePayableName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(BankPaidExpenseClearing(), BankPaidExpenseClearingName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetTravelExpense(), 80);
        ContosoGLAccount.InsertGLAccount(MileageReimbursement(), MileageReimbursementName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowance(), PerDiemAllowanceName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(BusinessMealsAndEntertainment(), BusinessMealsAndEntertainmentName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(OtherEmployeeExpenses(), OtherEmployeeExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Income, 80);
        ContosoGLAccount.InsertGLAccount(NonDeductibleEmployeeExpenses(), NonDeductibleEmployeeExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(CorporateCardExpensePayableName(), '1521');
        ContosoGLAccount.AddAccountForLocalization(BankPaidExpenseClearingName(), '1522');
        ContosoGLAccount.AddAccountForLocalization(MileageReimbursementName(), '3465');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceName(), '3466');
        ContosoGLAccount.AddAccountForLocalization(BusinessMealsAndEntertainmentName(), '3564');
        ContosoGLAccount.AddAccountForLocalization(OtherEmployeeExpensesName(), '4291');
        ContosoGLAccount.AddAccountForLocalization(NonDeductibleEmployeeExpensesName(), '4292');
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        CorporateCardExpensePayableTok: Label 'Corporate Card Expense Payable', MaxLength = 100;
        BankPaidExpenseClearingTok: Label 'Bank-Paid Expense Clearing Account', MaxLength = 100;
        MileageReimbursementTok: Label 'Mileage Reimbursement', MaxLength = 100;
        PerDiemAllowanceTok: Label 'Per Diem Allowance', MaxLength = 100;
        BusinessMealsAndEntertainmentTok: Label 'Business Meals and Entertainment', MaxLength = 100;
        OtherEmployeeExpensesTok: Label 'Other Employee Expenses', MaxLength = 100;
        NonDeductibleEmployeeExpensesTok: Label 'Non-Deductible Employee Expenses', MaxLength = 100;

    procedure CorporateCardExpensePayable(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CorporateCardExpensePayableName()));
    end;

    procedure CorporateCardExpensePayableName(): Text[100]
    begin
        exit(CorporateCardExpensePayableTok);
    end;

    procedure BankPaidExpenseClearing(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(BankPaidExpenseClearingName()));
    end;

    procedure BankPaidExpenseClearingName(): Text[100]
    begin
        exit(BankPaidExpenseClearingTok);
    end;

    procedure MileageReimbursement(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MileageReimbursementName()));
    end;

    procedure MileageReimbursementName(): Text[100]
    begin
        exit(MileageReimbursementTok);
    end;

    procedure PerDiemAllowance(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(PerDiemAllowanceName()));
    end;

    procedure PerDiemAllowanceName(): Text[100]
    begin
        exit(PerDiemAllowanceTok);
    end;

    procedure BusinessMealsAndEntertainment(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(BusinessMealsAndEntertainmentName()));
    end;

    procedure BusinessMealsAndEntertainmentName(): Text[100]
    begin
        exit(BusinessMealsAndEntertainmentTok);
    end;

    procedure OtherEmployeeExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherEmployeeExpensesName()));
    end;

    procedure OtherEmployeeExpensesName(): Text[100]
    begin
        exit(OtherEmployeeExpensesTok);
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
