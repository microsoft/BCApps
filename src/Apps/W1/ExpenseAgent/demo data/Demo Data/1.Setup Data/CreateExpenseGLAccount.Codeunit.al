// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoTool;
using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 8207 "Create Expense G/L Account"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        GLAccountIndent: Codeunit "G/L Account-Indent";
    begin
        AddExpenseVATAccountsForLocalization();
        InsertExpenseVATAccounts();
        AddGLAccountsForLocalization();

        GLAccountIndent.Indent();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create G/L Account", OnAfterAddGLAccountsForLocalization, '', false, false)]
    local procedure AddExpenseVATAccountsForLocalization()
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        CreateExpenseCountryData: Codeunit "Create Expense Country Data";
        CreateExpenseVATRates: Codeunit "Create Expense VAT Rates";
        VATRates: List of [Decimal];
        VATRate: Decimal;
        AccountNo: Integer;
    begin
        if not CreateExpenseCountryData.IsVATCountry() then
            exit;
        if not ContosoCoffeeDemoDataSetup.Get() then
            exit;

        VATRates := GetExpenseVATRates(ContosoCoffeeDemoDataSetup."Country/Region Code");
        AccountNo := 5650;
        foreach VATRate in VATRates do begin
            if AccountNo > 5659 then
                Error(ExpenseVATAccountRangeExceededErr, ContosoCoffeeDemoDataSetup."Country/Region Code");
            ContosoGLAccount.AddAccountForLocalization(CreateExpenseVATRates.GetExpenseVATAccountName(VATRate), Format(AccountNo));
            AccountNo += 1;
        end;
    end;

    local procedure InsertExpenseVATAccounts()
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        CreateExpenseCountryData: Codeunit "Create Expense Country Data";
        CreateExpenseVATRates: Codeunit "Create Expense VAT Rates";
        VATRates: List of [Decimal];
        VATRate: Decimal;
        SubCategory: Text[80];
    begin
        if not CreateExpenseCountryData.IsVATCountry() then
            exit;
        if not ContosoCoffeeDemoDataSetup.Get() then
            exit;

        VATRates := GetExpenseVATRates(ContosoCoffeeDemoDataSetup."Country/Region Code");
        SubCategory := CopyStr(GLAccountCategoryMgt.GetAR(), 1, MaxStrLen(SubCategory));
        foreach VATRate in VATRates do
            ContosoGLAccount.InsertGLAccount(
                ContosoGLAccount.GetAccountNo(CreateExpenseVATRates.GetExpenseVATAccountName(VATRate)),
                CreateExpenseVATRates.GetExpenseVATAccountName(VATRate),
                Enum::"G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory,
                Enum::"G/L Account Type"::Posting, '', '', 0, '', Enum::"General Posting Type"::" ", '', '', false, false, false);
    end;

    local procedure GetExpenseVATRates(CountryCode: Code[10]) VATRates: List of [Decimal]
    begin
        case CountryCode of
            'AT':
                AddExpenseVATRates(VATRates, 0, 10, 13, 20);
            'AU':
                AddExpenseVATRates(VATRates, 0, 10);
            'BE':
                AddExpenseVATRates(VATRates, 0, 6, 12, 21);
            'BG':
                AddExpenseVATRates(VATRates, 0, 9, 20);
            'CH':
                AddExpenseVATRates(VATRates, 0, 2.6, 3.8, 8.1);
            'CY':
                AddExpenseVATRates(VATRates, 0, 9, 19);
            'CZ':
                AddExpenseVATRates(VATRates, 0, 12, 21);
            'DE':
                AddExpenseVATRates(VATRates, 0, 7, 19);
            'DK':
                AddExpenseVATRates(VATRates, 0, 25);
            'EE':
                AddExpenseVATRates(VATRates, 0, 9, 22);
            'ES':
                AddExpenseVATRates(VATRates, 0, 10, 21);
            'FI':
                AddExpenseVATRates(VATRates, 0, 10, 13.5, 25.5);
            'FR':
                AddExpenseVATRates(VATRates, 0, 10, 20);
            'GB':
                AddExpenseVATRates(VATRates, 0, 20);
            'GR':
                AddExpenseVATRates(VATRates, 0, 13, 24);
            'HR':
                AddExpenseVATRates(VATRates, 0, 13, 25);
            'HU':
                AddExpenseVATRates(VATRates, 0, 18, 27);
            'IE':
                AddExpenseVATRates(VATRates, 0, 9, 13.5, 23);
            'IS':
                AddExpenseVATRates(VATRates, 0, 11, 24);
            'IT':
                AddExpenseVATRates(VATRates, 0, 10, 22);
            'LT':
                AddExpenseVATRates(VATRates, 0, 9, 21);
            'LU':
                AddExpenseVATRates(VATRates, 0, 8, 17);
            'LV':
                AddExpenseVATRates(VATRates, 0, 12, 21);
            'MT':
                AddExpenseVATRates(VATRates, 0, 5, 7, 18);
            'MX':
                AddExpenseVATRates(VATRates, 0, 16);
            'NL':
                AddExpenseVATRates(VATRates, 0, 9, 21);
            'NO':
                AddExpenseVATRates(VATRates, 0, 12, 15, 25);
            'NZ':
                AddExpenseVATRates(VATRates, 0, 15);
            'PL':
                AddExpenseVATRates(VATRates, 0, 8, 23);
            'PT':
                AddExpenseVATRates(VATRates, 0, 6, 13, 23);
            'RO':
                AddExpenseVATRates(VATRates, 0, 9, 19);
            'SE':
                AddExpenseVATRates(VATRates, 0, 6, 12, 25);
            'SI':
                AddExpenseVATRates(VATRates, 0, 9.5, 22);
            'SK':
                AddExpenseVATRates(VATRates, 0, 10, 23);
            'UA':
                AddExpenseVATRates(VATRates, 0, 20);
        end;
    end;

    local procedure AddExpenseVATRates(var VATRates: List of [Decimal]; VATRate1: Decimal; VATRate2: Decimal)
    begin
        VATRates.Add(VATRate1);
        VATRates.Add(VATRate2);
    end;

    local procedure AddExpenseVATRates(var VATRates: List of [Decimal]; VATRate1: Decimal; VATRate2: Decimal; VATRate3: Decimal)
    begin
        AddExpenseVATRates(VATRates, VATRate1, VATRate2);
        VATRates.Add(VATRate3);
    end;

    local procedure AddExpenseVATRates(var VATRates: List of [Decimal]; VATRate1: Decimal; VATRate2: Decimal; VATRate3: Decimal; VATRate4: Decimal)
    begin
        AddExpenseVATRates(VATRates, VATRate1, VATRate2, VATRate3);
        VATRates.Add(VATRate4);
    end;

    local procedure AddGLAccountsForLocalization()
    begin
        OnAfterAddGLAccountsForLocalization();
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        CompanyCreditCardsAccountTok: Label 'Company credit cards account', MaxLength = 100;
        PerDiemTravelExpensesTok: Label 'Per-diem travel expenses', MaxLength = 100;
        MileageTravelExpensesTok: Label 'Mileage travel expenses', MaxLength = 100;
        MealExpensesDeductibleTok: Label 'Meal expenses, deductible', MaxLength = 100;
        MealExpensesNondeductibleTok: Label 'Meal expenses, nondeductible', MaxLength = 100;
        OtherNondeductibleTravelExpensesTok: Label 'Other nondeductible travel expenses', MaxLength = 100;
        MiscExternalExpensesNondeductibleTok: Label 'Misc. external expenses, nondeductible', MaxLength = 100;
        EmployeePrepaymentsTok: Label 'Employee prepayments', MaxLength = 100;
        EmployeePrepaymentsExpensesTok: Label 'Employee Prepayments, Expenses', MaxLength = 100;
        EmployeePrepaymentsTotalTok: Label 'Employee Prepayments, Total', MaxLength = 100;
        RentalVehiclesTok: Label 'Rental vehicles', MaxLength = 100;
        BusinessEntertainingNondeductibleTok: Label 'Business Entertaining, nondeductible', MaxLength = 100;
        OtherTravelExpensesTok: Label 'Other travel expenses', MaxLength = 100;
        ExpenseVATAccountRangeExceededErr: Label 'More than ten Expense VAT rates are defined for country/region %1.', Comment = '%1 = country/region code';

    procedure FindGLAccountByName(AccountName: Text[100]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Name", AccountName);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        if GLAccount.FindFirst() then
            exit(GLAccount."No.")
        else
            exit('');
    end;

    procedure CompanyCreditCardsAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCreditCardsAccountName()));
    end;

    procedure CompanyCreditCardsAccountName(): Text[100]
    begin
        exit(CompanyCreditCardsAccountTok);
    end;

    procedure PerDiemTravelExpensesAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(PerDiemTravelExpensesAccountName()));
    end;

    procedure PerDiemTravelExpensesAccountName(): Text[100]
    begin
        exit(PerDiemTravelExpensesTok);
    end;

    procedure MileageTravelExpensesAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MileageTravelExpensesAccountName()));
    end;

    procedure MileageTravelExpensesAccountName(): Text[100]
    begin
        exit(MileageTravelExpensesTok);
    end;

    procedure MealExpensesDeductibleAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MealExpensesDeductibleAccountName()));
    end;

    procedure MealExpensesDeductibleAccountName(): Text[100]
    begin
        exit(MealExpensesDeductibleTok);
    end;

    procedure MealExpensesNondeductibleAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MealExpensesNondeductibleAccountName()));
    end;

    procedure MealExpensesNondeductibleAccountName(): Text[100]
    begin
        exit(MealExpensesNondeductibleTok);
    end;

    procedure OtherNondeductibleTravelExpensesAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherNondeductibleTravelExpensesAccountName()));
    end;

    procedure OtherNondeductibleTravelExpensesAccountName(): Text[100]
    begin
        exit(OtherNondeductibleTravelExpensesTok);
    end;

    procedure MiscExternalExpensesNondeductibleAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MiscExternalExpensesNondeductibleAccountName()));
    end;

    procedure MiscExternalExpensesNondeductibleAccountName(): Text[100]
    begin
        exit(MiscExternalExpensesNondeductibleTok);
    end;

    procedure EmployeePrepaymentsAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeePrepaymentsAccountName()));
    end;

    procedure EmployeePrepaymentsAccountName(): Text[100]
    begin
        exit(EmployeePrepaymentsTok);
    end;

    procedure EmployeePrepaymentsExpensesAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeePrepaymentsExpensesAccountName()));
    end;

    procedure EmployeePrepaymentsExpensesAccountName(): Text[100]
    begin
        exit(EmployeePrepaymentsExpensesTok);
    end;

    procedure EmployeePrepaymentsTotalAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeePrepaymentsTotalAccountName()));
    end;

    procedure EmployeePrepaymentsTotalAccountName(): Text[100]
    begin
        exit(EmployeePrepaymentsTotalTok);
    end;

    procedure RentalVehiclesAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(RentalVehiclesAccountName()));
    end;

    procedure RentalVehiclesAccountName(): Text[100]
    begin
        exit(RentalVehiclesTok);
    end;

    procedure BusinessEntertainingNondeductibleAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(BusinessEntertainingNondeductibleAccountName()));
    end;

    procedure BusinessEntertainingNondeductibleAccountName(): Text[100]
    begin
        exit(BusinessEntertainingNondeductibleTok);
    end;

    procedure OtherTravelExpensesAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherTravelExpensesAccountName()));
    end;

    procedure OtherTravelExpensesAccountName(): Text[100]
    begin
        exit(OtherTravelExpensesTok);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddGLAccountsForLocalization()
    begin
    end;
}