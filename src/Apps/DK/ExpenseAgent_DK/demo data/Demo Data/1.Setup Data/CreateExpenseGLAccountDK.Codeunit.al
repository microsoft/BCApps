// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 13675 "Create Expense G/L Account DK"
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
        ContosoGLAccount.InsertGLAccount(CompanyCreditCards(), CompanyCreditCardsName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(TravelAllowancesPerDiem(), TravelAllowancesPerDiemName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(NonDeductibleTravelExpenses(), NonDeductibleTravelExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(RentalCarExpenses(), RentalCarExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(OtherExpenses(), OtherExpensesName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCreditCardsName(), '18300');
        ContosoGLAccount.AddAccountForLocalization(TravelAllowancesPerDiemName(), '03652');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '03661');
        ContosoGLAccount.AddAccountForLocalization(NonDeductibleTravelExpensesName(), '03655');
        ContosoGLAccount.AddAccountForLocalization(RentalCarExpensesName(), '03654');
        ContosoGLAccount.AddAccountForLocalization(OtherExpensesName(), '05699');
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CompanyCreditCardsTok: Label 'Company credit cards', MaxLength = 100;
        TravelAllowancesPerDiemTok: Label 'Travel allowances (per diem)', MaxLength = 100;
        RentalCarExpensesTok: Label 'Rental car expenses', MaxLength = 100;
        NonDeductibleTravelExpensesTok: Label 'Non-deductible travel expenses', MaxLength = 100;
        OtherExpensesTok: Label 'Other expenses', MaxLength = 100;

    procedure CompanyCreditCards(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCreditCardsName()));
    end;

    procedure CompanyCreditCardsName(): Text[100]
    begin
        exit(CompanyCreditCardsTok);
    end;

    procedure TravelAllowancesPerDiem(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(TravelAllowancesPerDiemName()));
    end;

    procedure TravelAllowancesPerDiemName(): Text[100]
    begin
        exit(TravelAllowancesPerDiemTok);
    end;

    procedure RentalCarExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(RentalCarExpensesName()));
    end;

    procedure RentalCarExpensesName(): Text[100]
    begin
        exit(RentalCarExpensesTok);
    end;

    procedure NonDeductibleTravelExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(NonDeductibleTravelExpensesName()));
    end;

    procedure NonDeductibleTravelExpensesName(): Text[100]
    begin
        exit(NonDeductibleTravelExpensesTok);
    end;

    procedure OtherExpenses(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherExpensesName()));
    end;

    procedure OtherExpensesName(): Text[100]
    begin
        exit(OtherExpensesTok);
    end;
}