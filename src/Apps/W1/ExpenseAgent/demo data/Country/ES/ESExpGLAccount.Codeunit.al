// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 8277 "ES Exp. GL Account"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
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
        ContosoGLAccount.InsertGLAccount(CompanyCreditCardsClearingAccount(), CompanyCreditCardsClearingAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpensesPrepayments(), ExpensesPrepaymentsName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.PerDiemTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.MileageTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesDeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(RentalCarExpenses(), RentalCarExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(TravelExpenses(), TravelExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(EntertainmentExpensesAccount(), EntertainmentExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(RoundingExpensesOperatingAccount(), RoundingExpensesOperatingAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        UpdateIncomeStatementBalanceAccount();
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCreditCardsClearingAccountName(), '5721001');
        ContosoGLAccount.AddAccountForLocalization(ExpensesPrepaymentsName(), '4800001');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '6291002');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '6291003');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '6292001');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '6292002');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), '6299001');
        ContosoGLAccount.AddAccountForLocalization(RentalCarExpensesName(), '6291004');
        ContosoGLAccount.AddAccountForLocalization(TravelExpensesName(), '6291001');
        ContosoGLAccount.AddAccountForLocalization(EntertainmentExpensesAccountName(), '6293001');
        ContosoGLAccount.AddAccountForLocalization(RoundingExpensesOperatingAccountName(), '6298001');
    end;

    local procedure UpdateIncomeStatementBalanceAccount()
    begin
        UpdateIncomeStmtBalAcc(CompanyCreditCardsClearingAccount(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAcc(ExpensesPrepayments(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAcc(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAcc(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAcc(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAcc(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAcc(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAcc(RentalCarExpenses(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAcc(TravelExpenses(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAcc(EntertainmentExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAcc(RoundingExpensesOperatingAccount(), ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.ProfitOrLossName()));
    end;

    local procedure UpdateIncomeStmtBalAcc(No: Code[20]; IncomeStmtBalAcc: Code[20])
    var
        GLAccount: Record "G/L Account";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        i: Integer;
    begin
        // "Income Stmt. Bal. Acc." is added by the ES localization to table G/L Account.
        // Look it up dynamically via FieldRef so this demo data works without an ES-loc
        // compile-time dependency; silently skip when the field is not present.
        if not GLAccount.Get(No) then
            exit;

        RecRef.GetTable(GLAccount);
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            if FieldRef.Name = 'Income Stmt. Bal. Acc.' then begin
                FieldRef.Validate(IncomeStmtBalAcc);
                RecRef.Modify();
                exit;
            end;
        end;
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        ESGLAccountNames: Codeunit "ES GL Account Names";
        CompanyCreditCardsClearingAccountTok: Label 'Company credit card clearing account', MaxLength = 100;
        TravelExpensesTok: Label 'Travel expenses', MaxLength = 100;
        ExpensesPrepaymentsTok: Label 'Expenses Prepayments', MaxLength = 100;
        RentalCarExpensesTok: Label 'Rental Car Expenses', MaxLength = 100;
        EntertainmentExpensesTok: Label 'Entertainment expenses', MaxLength = 100;
        RoundingExpensesOperatingTok: Label 'Rounding Expenses (Operating)', MaxLength = 100;

    procedure CompanyCreditCardsClearingAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCreditCardsClearingAccountName()));
    end;

    procedure CompanyCreditCardsClearingAccountName(): Text[100]
    begin
        exit(CompanyCreditCardsClearingAccountTok);
    end;

    procedure TravelExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(TravelExpensesName()));
    end;

    procedure TravelExpensesName(): Text[100]
    begin
        exit(TravelExpensesTok);
    end;

    procedure ExpensesPrepayments(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(ExpensesPrepaymentsName()));
    end;

    procedure ExpensesPrepaymentsName(): Text[100]
    begin
        exit(ExpensesPrepaymentsTok);
    end;

    procedure RentalCarExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(RentalCarExpensesName()));
    end;

    procedure RentalCarExpensesName(): Text[100]
    begin
        exit(RentalCarExpensesTok);
    end;

    procedure EntertainmentExpensesAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EntertainmentExpensesAccountName()));
    end;

    procedure EntertainmentExpensesAccountName(): Text[100]
    begin
        exit(EntertainmentExpensesTok);
    end;

    procedure RoundingExpensesOperatingAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(RoundingExpensesOperatingAccountName()));
    end;

    procedure RoundingExpensesOperatingAccountName(): Text[100]
    begin
        exit(RoundingExpensesOperatingTok);
    end;
}
