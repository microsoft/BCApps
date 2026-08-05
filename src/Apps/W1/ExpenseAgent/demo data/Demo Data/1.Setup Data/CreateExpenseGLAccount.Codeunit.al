// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 8207 "Create Expense G/L Account"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        GLAccountIndent: Codeunit "G/L Account-Indent";
    begin
        AddGLAccountsForLocalization();

        GLAccountIndent.Indent();
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

    procedure FindGLAccountByName(AccountName: Text[100]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Name", AccountName);
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