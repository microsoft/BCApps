// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 8225 "Create Expense Posting Groups"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Table, Database::"Expense Posting Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnInsertRecord(var Rec: Record "Expense Posting Group")
    begin
        case CountryCode of
            'AT':
                OnInsertRecordAT(Rec);
            'AU':
                OnInsertRecordAU(Rec);
            'BE':
                OnInsertRecordBE(Rec);
            'CA':
                OnInsertRecordCA(Rec);
            'CH':
                OnInsertRecordCH(Rec);
            'CZ':
                OnInsertRecordCZ(Rec);
            'DE':
                OnInsertRecordDE(Rec);
            'DK':
                OnInsertRecordDK(Rec);
            'ES':
                OnInsertRecordES(Rec);
            'FI':
                OnInsertRecordFI(Rec);
            'FR':
                OnInsertRecordFR(Rec);
            'GB':
                OnInsertRecordGB(Rec);
            'IT':
                OnInsertRecordIT(Rec);
            'NL':
                OnInsertRecordNL(Rec);
            'NO':
                OnInsertRecordNO(Rec);
            'NZ':
                OnInsertRecordNZ(Rec);
            'US':
                OnInsertRecordUS(Rec);
        end;
    end;

    local procedure OnInsertRecordAT(var Rec: Record "Expense Posting Group")
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.HospitalityDomesticDeductibleAmountName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.KilometerAllowanceName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherName()), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            ExpensePerDiemI():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.MealExpensesDomesticName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            ExpensePerDiemA():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.MealExpensesAbroadName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TransportationThirdPartiesName()), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TransportationThirdPartiesName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
        end;
    end;

    local procedure OnInsertRecordAU(var Rec: Record "Expense Posting Group")
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.EntertainmentandPRName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.BusinessEntertainingNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.OtherTravelExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.RentalVehiclesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
        end;
    end;

    local procedure OnInsertRecordBE(var Rec: Record "Expense Posting Group")
    var
        CreateExpGLAccounts: Codeunit "Create Expense G/L Accounts";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.EntertainmentAndPRName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesBE(), CreateExpGLAccounts.EmployeeTravelAdvancesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, CreateExpGLAccounts.BusinessMealsBE(), CreateExpGLAccounts.NonRefundableEmployeeExpensesBE(), CreateExpGLAccounts.EmployeeTravelAdvancesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, CreateExpGLAccounts.MileageAllowanceBE(), CreateExpGLAccounts.NonRefundableEmployeeExpensesBE(), CreateExpGLAccounts.EmployeeTravelAdvancesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, CreateExpGLAccounts.OtherEmployeeExpensesBE(), CreateExpGLAccounts.NonRefundableEmployeeExpensesBE(), CreateExpGLAccounts.EmployeeTravelAdvancesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE());
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccounts.PerDiemAllowanceBE(), CreateExpGLAccounts.NonRefundableEmployeeExpensesBE(), CreateExpGLAccounts.EmployeeTravelAdvancesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TravelName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesBE(), CreateExpGLAccounts.EmployeeTravelAdvancesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TravelName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesBE(), CreateExpGLAccounts.EmployeeTravelAdvancesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE(), CreateExpGLAccounts.ExpenseRoundingDifferencesBE());
        end;
    end;

    local procedure OnInsertRecordCA(var Rec: Record "Expense Posting Group")
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.EntertainmentandPRName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.OtherTravelExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.RentalVehiclesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
        end;
    end;

    local procedure OnInsertRecordCH(var Rec: Record "Expense Posting Group")
    var
        CreateExpGLAccounts: Codeunit "Create Expense G/L Accounts";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, CreateExpGLAccounts.EntertainmentExpensesCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPersonnelCostsName()), CreateExpGLAccounts.EmployeeExpenseAdvancesCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, CreateExpGLAccounts.MealsAndHospitalityExpensesCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPersonnelCostsName()), CreateExpGLAccounts.EmployeeExpenseAdvancesCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, CreateExpGLAccounts.MileageAllowanceCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPersonnelCostsName()), CreateExpGLAccounts.EmployeeExpenseAdvancesCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.MiscCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPersonnelCostsName()), CreateExpGLAccounts.EmployeeExpenseAdvancesCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccounts.PerDiemAllowanceCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPersonnelCostsName()), CreateExpGLAccounts.EmployeeExpenseAdvancesCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TravelCostsCustomerServiceName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPersonnelCostsName()), CreateExpGLAccounts.EmployeeExpenseAdvancesCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TravelCostsCustomerServiceName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPersonnelCostsName()), CreateExpGLAccounts.EmployeeExpenseAdvancesCH(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RoundingDifferencesPurchaseName()));
        end;
    end;

    local procedure OnInsertRecordCZ(var Rec: Record "Expense Posting Group")
    var
        CreateExpGLAccounts: Codeunit "Create Expense G/L Accounts";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RepresentationCostsName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesCZ(), CreateExpGLAccounts.EmployeeExpenseAdvancesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, CreateExpGLAccounts.MealsAndHospitalityExpensesCZ(), CreateExpGLAccounts.NonRefundableEmployeeExpensesCZ(), CreateExpGLAccounts.EmployeeExpenseAdvancesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, CreateExpGLAccounts.MileageAllowanceCZ(), CreateExpGLAccounts.NonRefundableEmployeeExpensesCZ(), CreateExpGLAccounts.EmployeeExpenseAdvancesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ());
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccounts.PerDiemAllowanceCZ(), CreateExpGLAccounts.NonRefundableEmployeeExpensesCZ(), CreateExpGLAccounts.EmployeeExpenseAdvancesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccounts.CarRentalExpensesCZ(), CreateExpGLAccounts.NonRefundableEmployeeExpensesCZ(), CreateExpGLAccounts.EmployeeExpenseAdvancesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TravelExpensesName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesCZ(), CreateExpGLAccounts.EmployeeExpenseAdvancesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherOperatingExpensesName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesCZ(), CreateExpGLAccounts.EmployeeExpenseAdvancesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ(), CreateExpGLAccounts.ExpenseRoundingDifferencesCZ());
        end;
    end;

    local procedure OnInsertRecordDE(var Rec: Record "Expense Posting Group")
    var
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.BusinessEntertainingdeductibleName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.BoardandlodgingName()), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.MiscexternalexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OthertravelexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OthertravelexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OthertravelexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RentalvehiclesName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SalesInvoiceRoundingName()));
        end;
    end;

    local procedure OnInsertRecordDK(var Rec: Record "Expense Posting Group")
    var
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpGLAccounts: Codeunit "Create Expense G/L Accounts";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.EntwinetobaccospiritsName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RestaurantdiningName()), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.MileagerateName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, CreateExpGLAccounts.OtherExpensesDK(), CreateExpGLAccounts.NonDeductibleTravelExpensesDK(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccounts.TravelAllowancesPerDiemDK(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TravelingtradefairsetcName()), CreateExpGLAccounts.NonDeductibleTravelExpensesDK(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccounts.RentalCarExpensesDK(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CentdiscrepanciesName()));
        end;
    end;

    local procedure OnInsertRecordES(var Rec: Record "Expense Posting Group")
    var
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpGLAccounts: Codeunit "Create Expense G/L Accounts";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, CreateExpGLAccounts.EntertainmentExpensesAccountES(), '', CreateExpGLAccounts.ExpensesPrepaymentsES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccount(), CreateExpGLAccounts.ExpensesPrepaymentsES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', CreateExpGLAccounts.ExpensesPrepaymentsES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherBusinessExpensesName()), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), CreateExpGLAccounts.ExpensesPrepaymentsES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES());
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', CreateExpGLAccounts.ExpensesPrepaymentsES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, CreateExpGLAccounts.TravelExpensesES(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), CreateExpGLAccounts.ExpensesPrepaymentsES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccounts.RentalCarExpensesES(), '', CreateExpGLAccounts.ExpensesPrepaymentsES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES(), CreateExpGLAccounts.RoundingExpensesOperatingAccountES());
        end;
    end;

    local procedure OnInsertRecordFI(var Rec: Record "Expense Posting Group")
    var
        CreateExpGLAccounts: Codeunit "Create Expense G/L Accounts";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, CreateExpGLAccounts.EntertainmentExpensesFI(), CreateExpGLAccounts.NonRefundableEmployeeExpensesFI(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.Otherreceivables1Name()), CreateExpGLAccounts.ExpenseRoundingDifferencesFI(), CreateExpGLAccounts.ExpenseRoundingDifferencesFI());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, CreateExpGLAccounts.BusinessMealExpensesFI(), CreateExpGLAccounts.NonRefundableEmployeeExpensesFI(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.Otherreceivables1Name()), CreateExpGLAccounts.ExpenseRoundingDifferencesFI(), CreateExpGLAccounts.ExpenseRoundingDifferencesFI());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, CreateExpGLAccounts.MileageAllowanceFI(), CreateExpGLAccounts.NonRefundableEmployeeExpensesFI(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.Otherreceivables1Name()), CreateExpGLAccounts.ExpenseRoundingDifferencesFI(), CreateExpGLAccounts.ExpenseRoundingDifferencesFI());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, CreateExpGLAccounts.OtherEmployeeExpensesFI(), CreateExpGLAccounts.NonRefundableEmployeeExpensesFI(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.Otherreceivables1Name()), CreateExpGLAccounts.ExpenseRoundingDifferencesFI(), CreateExpGLAccounts.ExpenseRoundingDifferencesFI());
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccounts.PerDiemAllowanceFI(), CreateExpGLAccounts.NonRefundableEmployeeExpensesFI(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.Otherreceivables1Name()), CreateExpGLAccounts.ExpenseRoundingDifferencesFI(), CreateExpGLAccounts.ExpenseRoundingDifferencesFI());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, CreateExpGLAccounts.OtherTravelExpensesFI(), CreateExpGLAccounts.NonRefundableEmployeeExpensesFI(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.Otherreceivables1Name()), CreateExpGLAccounts.ExpenseRoundingDifferencesFI(), CreateExpGLAccounts.ExpenseRoundingDifferencesFI());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccounts.CarRentalExpensesFI(), CreateExpGLAccounts.NonRefundableEmployeeExpensesFI(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.Otherreceivables1Name()), CreateExpGLAccounts.ExpenseRoundingDifferencesFI(), CreateExpGLAccounts.ExpenseRoundingDifferencesFI());
        end;
    end;

    local procedure OnInsertRecordFR(var Rec: Record "Expense Posting Group")
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpGLAccounts: Codeunit "Create Expense G/L Accounts";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.EntertainmentandPRName()), '', CreateExpGLAccounts.ExpensePrepaymentAccountFR(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccount(), CreateExpGLAccounts.ExpensePrepaymentAccountFR(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', CreateExpGLAccounts.ExpensePrepaymentAccountFR(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.OtherTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), CreateExpGLAccounts.ExpensePrepaymentAccountFR(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', CreateExpGLAccounts.ExpensePrepaymentAccountFR(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.TravelName()), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), CreateExpGLAccounts.ExpensePrepaymentAccountFR(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccounts.RentalCarExpensesFR(), '', CreateExpGLAccounts.ExpensePrepaymentAccountFR(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
        end;
    end;

    local procedure OnInsertRecordGB(var Rec: Record "Expense Posting Group")
    var
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.BusinessEntertainingDeductibleName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.MiscExternalExpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherTravelExpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RentalVehiclesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
        end;
    end;

    local procedure OnInsertRecordIT(var Rec: Record "Expense Posting Group")
    var
        CreateExpGLAccounts: Codeunit "Create Expense G/L Accounts";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.EntertainmentAndPRName()), CreateExpGLAccounts.NonDeductibleEmployeeExpensesIT(), CreateExpGLAccounts.EmployeeAdvancesPrepaymentsIT(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.EntertainmentAndPRName()), CreateExpGLAccounts.NonDeductibleEmployeeExpensesIT(), CreateExpGLAccounts.EmployeeAdvancesPrepaymentsIT(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.GasolineAndMotorOilName()), CreateExpGLAccounts.NonDeductibleEmployeeExpensesIT(), CreateExpGLAccounts.EmployeeAdvancesPrepaymentsIT(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.MiscellaneousName()), CreateExpGLAccounts.NonDeductibleEmployeeExpensesIT(), CreateExpGLAccounts.EmployeeAdvancesPrepaymentsIT(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccounts.PerDiemAllowanceIT(), CreateExpGLAccounts.NonDeductibleEmployeeExpensesIT(), CreateExpGLAccounts.EmployeeAdvancesPrepaymentsIT(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TravelName()), CreateExpGLAccounts.NonDeductibleEmployeeExpensesIT(), CreateExpGLAccounts.EmployeeAdvancesPrepaymentsIT(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccounts.CarRentalExpensesIT(), CreateExpGLAccounts.NonDeductibleEmployeeExpensesIT(), CreateExpGLAccounts.EmployeeAdvancesPrepaymentsIT(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.InvoiceRoundingName()));
        end;
    end;

    local procedure OnInsertRecordNL(var Rec: Record "Expense Posting Group")
    var
        CreateExpGLAccounts: Codeunit "Create Expense G/L Accounts";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, CreateExpGLAccounts.BusinessMealsAndEntertainmentNL(), CreateExpGLAccounts.NonDeductibleEmployeeExpensesNL(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.BoardAndLodgingName()), CreateExpGLAccounts.NonDeductibleEmployeeExpensesNL(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, CreateExpGLAccounts.MileageReimbursementNL(), CreateExpGLAccounts.NonDeductibleEmployeeExpensesNL(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, CreateExpGLAccounts.OtherEmployeeExpensesNL(), CreateExpGLAccounts.NonDeductibleEmployeeExpensesNL(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccounts.PerDiemAllowanceNL(), CreateExpGLAccounts.NonDeductibleEmployeeExpensesNL(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherTravelExpensesName()), CreateExpGLAccounts.NonDeductibleEmployeeExpensesNL(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RentalVehiclesName()), CreateExpGLAccounts.NonDeductibleEmployeeExpensesNL(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
        end;
    end;

    local procedure OnInsertRecordNO(var Rec: Record "Expense Posting Group")
    var
        CreateExpGLAccounts: Codeunit "Create Expense G/L Accounts";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.EntertainmentDeductibleName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesNO(), CreateExpGLAccounts.EmployeeExpensePrepaymentsNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.EntertainmentDeductibleName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesNO(), CreateExpGLAccounts.EmployeeExpensePrepaymentsNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CarAllowanceName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesNO(), CreateExpGLAccounts.EmployeeExpensePrepaymentsNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AdministrativeExpensesName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesNO(), CreateExpGLAccounts.EmployeeExpensePrepaymentsNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO());
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SubsistenceName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesNO(), CreateExpGLAccounts.EmployeeExpensePrepaymentsNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TravelName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesNO(), CreateExpGLAccounts.EmployeeExpensePrepaymentsNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.TravelName()), CreateExpGLAccounts.NonRefundableEmployeeExpensesNO(), CreateExpGLAccounts.EmployeeExpensePrepaymentsNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO(), CreateExpGLAccounts.ExpenseRoundingDifferencesNO());
        end;
    end;

    local procedure OnInsertRecordNZ(var Rec: Record "Expense Posting Group")
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.EntertainmentandPRName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.TravelName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.RentalVehiclesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
        end;
    end;

    local procedure OnInsertRecordUS(var Rec: Record "Expense Posting Group")
    var
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.BusinessEntertainingDeductibleName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.MiscExternalExpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherTravelExpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RentalVehiclesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayableInvoiceRoundingName()));
        end;
    end;

    local procedure ValidateRecordFields(var ExpensePostingGroup: Record "Expense Posting Group"; RefundableDebitAccount: Code[20]; NonRefundableDebitAccount: Code[20]; PrepaymentCreditAccount: Code[20]; ExpenseDebitRoundingAccount: Code[20]; ExpenseCreditRoundingAccount: Code[20])
    begin
        ExpensePostingGroup.Validate("Refundable Debit Account", RefundableDebitAccount);
        ExpensePostingGroup.Validate("Non-Refundable Debit Account", NonRefundableDebitAccount);
        ExpensePostingGroup.Validate("Prepayment Credit Account", PrepaymentCreditAccount);
        ExpensePostingGroup.Validate("Debit Rounding Account", ExpenseDebitRoundingAccount);
        ExpensePostingGroup.Validate("Credit Rounding Account", ExpenseCreditRoundingAccount);
    end;

    procedure SetCountryCode(NewCountryCode: Code[10])
    begin
        CountryCode := NewCountryCode;
    end;

    local procedure ExpensePerDiem(): Code[20]
    begin
        exit(ExpensePERDIEMTok);
    end;

    local procedure ExpensePerDiemI(): Code[20]
    begin
        exit(ExpensePERDIEMITok);
    end;

    local procedure ExpensePerDiemA(): Code[20]
    begin
        exit(ExpensePERDIEMATok);
    end;

    var
        CountryCode: Code[10];
        ExpensePERDIEMTok: Label 'EXPENSE-PERDIEM', MaxLength = 20, Locked = true;
        ExpensePERDIEMITok: Label 'EXPENSE-PERDIEM-I', MaxLength = 20, Locked = true;
        ExpensePERDIEMATok: Label 'EXPENSE-PERDIEM-A', MaxLength = 20, Locked = true;
}