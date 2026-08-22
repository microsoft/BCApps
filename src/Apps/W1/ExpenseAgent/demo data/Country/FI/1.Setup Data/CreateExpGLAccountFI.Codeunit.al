// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 8457 "Create Exp. GL Account FI"
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
        ContosoGLAccount.InsertGLAccount(CompanyCardExpenseClearing(), CompanyCardExpenseClearingName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CompanyPaidExpenseClearing(), CompanyPaidExpenseClearingName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetTravelExpense(), 80);
        ContosoGLAccount.InsertGLAccount(BusinessMealExpenses(), BusinessMealExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(MileageAllowance(), MileageAllowanceName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowance(), PerDiemAllowanceName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CarRentalExpenses(), CarRentalExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(OtherTravelExpenses(), OtherTravelExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        ContosoGLAccount.InsertGLAccount(EntertainmentExpenses(), EntertainmentExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(OtherEmployeeExpenses(), OtherEmployeeExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Income, 80);
        ContosoGLAccount.InsertGLAccount(NonRefundableEmployeeExpenses(), NonRefundableEmployeeExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseRoundingDifferences(), ExpenseRoundingDifferencesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCardExpenseClearingName(), '2916');
        ContosoGLAccount.AddAccountForLocalization(CompanyPaidExpenseClearingName(), '2917');
        ContosoGLAccount.AddAccountForLocalization(EntertainmentExpensesName(), '6160');
        ContosoGLAccount.AddAccountForLocalization(BusinessMealExpensesName(), '6161');
        ContosoGLAccount.AddAccountForLocalization(MileageAllowanceName(), '6162');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceName(), '6163');
        ContosoGLAccount.AddAccountForLocalization(CarRentalExpensesName(), '6164');
        ContosoGLAccount.AddAccountForLocalization(OtherTravelExpensesName(), '6165');
        ContosoGLAccount.AddAccountForLocalization(OtherEmployeeExpensesName(), '6166');
        ContosoGLAccount.AddAccountForLocalization(NonRefundableEmployeeExpensesName(), '6167');
        ContosoGLAccount.AddAccountForLocalization(ExpenseRoundingDifferencesName(), '6168');
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        CompanyCardExpenseClearingTok: Label 'Company Card Expense Clearing', MaxLength = 100;
        CompanyPaidExpenseClearingTok: Label 'Company-Paid Expense Clearing', MaxLength = 100;
        EntertainmentExpensesTok: Label 'Entertainment Expenses', MaxLength = 100;
        BusinessMealExpensesTok: Label 'Business Meal Expenses', MaxLength = 100;
        MileageAllowanceTok: Label 'Mileage Allowance', MaxLength = 100;
        PerDiemAllowanceTok: Label 'Per-Diem Allowance', MaxLength = 100;
        CarRentalExpensesTok: Label 'Car Rental Expenses', MaxLength = 100;
        OtherTravelExpensesTok: Label 'Other Travel Expenses', MaxLength = 100;
        OtherEmployeeExpensesTok: Label 'Other Employee Expenses', MaxLength = 100;
        NonRefundableEmployeeExpensesTok: Label 'Non-Refundable Employee Expenses', MaxLength = 100;
        ExpenseRoundingDifferencesTok: Label 'Expense Rounding Differences', MaxLength = 100;

    procedure CompanyCardExpenseClearing(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCardExpenseClearingName()));
    end;

    procedure CompanyCardExpenseClearingName(): Text[100]
    begin
        exit(CompanyCardExpenseClearingTok);
    end;

    procedure CompanyPaidExpenseClearing(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyPaidExpenseClearingName()));
    end;

    procedure CompanyPaidExpenseClearingName(): Text[100]
    begin
        exit(CompanyPaidExpenseClearingTok);
    end;

    procedure EntertainmentExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EntertainmentExpensesName()));
    end;

    procedure EntertainmentExpensesName(): Text[100]
    begin
        exit(EntertainmentExpensesTok);
    end;

    procedure BusinessMealExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(BusinessMealExpensesName()));
    end;

    procedure BusinessMealExpensesName(): Text[100]
    begin
        exit(BusinessMealExpensesTok);
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

    procedure OtherTravelExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherTravelExpensesName()));
    end;

    procedure OtherTravelExpensesName(): Text[100]
    begin
        exit(OtherTravelExpensesTok);
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
