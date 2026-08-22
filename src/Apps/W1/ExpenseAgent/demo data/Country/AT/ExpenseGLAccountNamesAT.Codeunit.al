// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8324 "Expense GL Account Names AT"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SettlementAccountCashBankTok: Label 'Settlement account cash bank', MaxLength = 100;
        SalesRevenuesResourcesExportTok: Label 'Sales revenues resources export', MaxLength = 100;
        TransportationThirdPartiesTok: Label 'Transportation third parties', MaxLength = 100;
        KilometerAllowanceTok: Label 'Kilometer allowance', MaxLength = 100;
        MealExpensesDomesticTok: Label 'Meal expenses domestic', MaxLength = 100;
        MealExpensesAbroadTok: Label 'Meal expenses abroad', MaxLength = 100;
        HospitalityDomesticDeductibleAmountTok: Label 'Hospitality domestic deductible amount', MaxLength = 100;
        OtherTok: Label 'Other', MaxLength = 100;

    procedure SettlementAccountCashBankName(): Text[100]
    begin
        exit(SettlementAccountCashBankTok);
    end;

    procedure SalesRevenuesResourcesExportName(): Text[100]
    begin
        exit(SalesRevenuesResourcesExportTok);
    end;

    procedure TransportationThirdPartiesName(): Text[100]
    begin
        exit(TransportationThirdPartiesTok);
    end;

    procedure KilometerAllowanceName(): Text[100]
    begin
        exit(KilometerAllowanceTok);
    end;

    procedure MealExpensesDomesticName(): Text[100]
    begin
        exit(MealExpensesDomesticTok);
    end;

    procedure MealExpensesAbroadName(): Text[100]
    begin
        exit(MealExpensesAbroadTok);
    end;

    procedure HospitalityDomesticDeductibleAmountName(): Text[100]
    begin
        exit(HospitalityDomesticDeductibleAmountTok);
    end;

    procedure OtherName(): Text[100]
    begin
        exit(OtherTok);
    end;
}
