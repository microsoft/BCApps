// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8220 "Expense GL Account Names"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure AccountsPayableDomesticName(): Text[100]
    begin
        exit(AccountsPayableDomesticTok);
    end;

    procedure AccountsPayablePostingName(): Text[100]
    begin
        exit(AccountsPayablePostingTok);
    end;

    procedure AdministrativeExpensesName(): Text[100]
    begin
        exit(AdministrativeExpensesTok);
    end;

    procedure AssetsintheformofprepaidexpensesName(): Text[100]
    begin
        exit(AssetsintheformofprepaidexpensesTok);
    end;

    procedure BankAccountKBName(): Text[100]
    begin
        exit(BankAccountKBTok);
    end;

    procedure BankName(): Text[100]
    begin
        exit(BankTok);
    end;

    procedure BanksEuroName(): Text[100]
    begin
        exit(BanksEuroTok);
    end;

    procedure BoardAndLodgingName(): Text[100]
    begin
        exit(BoardAndLodgingTok);
    end;

    procedure BusinessaccountOperatingDomesticName(): Text[100]
    begin
        exit(BusinessaccountOperatingDomesticTok);
    end;

    procedure BusinessEntertainingDeductibleName(): Text[100]
    begin
        exit(BusinessEntertainingDeductibleTok);
    end;

    procedure CarAllowanceName(): Text[100]
    begin
        exit(CarAllowanceTok);
    end;

    procedure CentdiscrepanciesName(): Text[100]
    begin
        exit(CentdiscrepanciesTok);
    end;

    procedure CurrentLiabilitiesToEmployeesName(): Text[100]
    begin
        exit(CurrentLiabilitiesToEmployeesTok);
    end;

    procedure CurrentReceivableFromEmployeesName(): Text[100]
    begin
        exit(CurrentReceivableFromEmployeesTok);
    end;

    procedure DomesticsalesofgoodsandservicesName(): Text[100]
    begin
        exit(DomesticsalesofgoodsandservicesTok);
    end;

    procedure EmployeesPayableName(): Text[100]
    begin
        exit(EmployeesPayableTok);
    end;

    procedure EntertainmentAndPRName(): Text[100]
    begin
        exit(EntertainmentAndPRTok);
    end;

    procedure EntertainmentDeductibleName(): Text[100]
    begin
        exit(EntertainmentDeductibleTok);
    end;

    procedure EntwinetobaccospiritsName(): Text[100]
    begin
        exit(EntwinetobaccospiritsTok);
    end;

    procedure GasolineAndMotorOilName(): Text[100]
    begin
        exit(GasolineAndMotorOilTok);
    end;

    procedure HospitalityDomesticDeductibleAmountName(): Text[100]
    begin
        exit(HospitalityDomesticDeductibleAmountTok);
    end;

    procedure InternalResourcesName(): Text[100]
    begin
        exit(InternalResourcesTok);
    end;

    procedure InvoiceRoundingName(): Text[100]
    begin
        exit(InvoiceRoundingTok);
    end;

    procedure JobSalesAppliedAccountName(): Text[100]
    begin
        exit(JobSalesAppliedAccountTok);
    end;

    procedure KilometerAllowanceName(): Text[100]
    begin
        exit(KilometerAllowanceTok);
    end;

    procedure MealExpensesAbroadName(): Text[100]
    begin
        exit(MealExpensesAbroadTok);
    end;

    procedure MealExpensesDomesticName(): Text[100]
    begin
        exit(MealExpensesDomesticTok);
    end;

    procedure MileagerateName(): Text[100]
    begin
        exit(MileagerateTok);
    end;

    procedure MiscCostsName(): Text[100]
    begin
        exit(MiscCostsTok);
    end;

    procedure MiscellaneousName(): Text[100]
    begin
        exit(MiscellaneousTok);
    end;

    procedure MiscExternalExpensesName(): Text[100]
    begin
        exit(MiscExternalExpensesTok);
    end;

    procedure OtherBankAccountsName(): Text[100]
    begin
        exit(OtherBankAccountsTok);
    end;

    procedure OtherBusinessExpensesName(): Text[100]
    begin
        exit(OtherBusinessExpensesTok);
    end;

    procedure OtherIncidentalRevenueName(): Text[100]
    begin
        exit(OtherIncidentalRevenueTok);
    end;

    procedure OtherName(): Text[100]
    begin
        exit(OtherTok);
    end;

    procedure OtherOperatingExpensesName(): Text[100]
    begin
        exit(OtherOperatingExpensesTok);
    end;

    procedure OtherPersonnelCostsName(): Text[100]
    begin
        exit(OtherPersonnelCostsTok);
    end;

    procedure OtherPrepaidExpensesAndAccruedIncomeName(): Text[100]
    begin
        exit(OtherPrepaidExpensesAndAccruedIncomeTok);
    end;

    procedure Otherreceivables1Name(): Text[100]
    begin
        exit(Otherreceivables1Tok);
    end;

    procedure OtherTravelExpensesName(): Text[100]
    begin
        exit(OtherTravelExpensesTok);
    end;

    procedure PayableInvoiceRoundingName(): Text[100]
    begin
        exit(PayableInvoiceRoundingTok);
    end;

    procedure PayablesToEmployeesName(): Text[100]
    begin
        exit(PayablesToEmployeesTok);
    end;

    procedure PrepaymentsAccruedCostsName(): Text[100]
    begin
        exit(PrepaymentsAccruedCostsTok);
    end;

    procedure ProfitOrLossName(): Text[100]
    begin
        exit(ProfitOrLossTok);
    end;

    procedure RemunerationAdvancesName(): Text[100]
    begin
        exit(RemunerationAdvancesTok);
    end;

    procedure RentalVehiclesName(): Text[100]
    begin
        exit(RentalVehiclesTok);
    end;

    procedure RepresentationCostsName(): Text[100]
    begin
        exit(RepresentationCostsTok);
    end;

    procedure RestaurantdiningName(): Text[100]
    begin
        exit(RestaurantdiningTok);
    end;

    procedure RoundingDifferencesPurchaseName(): Text[100]
    begin
        exit(RoundingDifferencesPurchaseTok);
    end;

    procedure SaleofResourceName(): Text[100]
    begin
        exit(SaleofResourceTok);
    end;

    procedure SaleofResourcesName(): Text[100]
    begin
        exit(SaleofResourcesTok);
    end;

    procedure SalesGoodsDomesticName(): Text[100]
    begin
        exit(SalesGoodsDomesticTok);
    end;

    procedure SalesInvoiceRoundingName(): Text[100]
    begin
        exit(SalesInvoiceRoundingTok);
    end;

    procedure SalesofgoodsdomName(): Text[100]
    begin
        exit(SalesofgoodsdomTok);
    end;

    procedure SalesOtherJobExpensesName(): Text[100]
    begin
        exit(SalesOtherJobExpensesTok);
    end;

    procedure SalesResourcesDomName(): Text[100]
    begin
        exit(SalesResourcesDomTok);
    end;

    procedure SalesRevenuesResourcesExportName(): Text[100]
    begin
        exit(SalesRevenuesResourcesExportTok);
    end;

    procedure SettlementAccountCashBankName(): Text[100]
    begin
        exit(SettlementAccountCashBankTok);
    end;

    procedure SubsistenceName(): Text[100]
    begin
        exit(SubsistenceTok);
    end;

    procedure TransportationThirdPartiesName(): Text[100]
    begin
        exit(TransportationThirdPartiesTok);
    end;

    procedure TravelCostsCustomerServiceName(): Text[100]
    begin
        exit(TravelCostsCustomerServiceTok);
    end;

    procedure TravelExpensesName(): Text[100]
    begin
        exit(TravelExpensesTok);
    end;

    procedure TravelingtradefairsetcName(): Text[100]
    begin
        exit(TravelingtradefairsetcTok);
    end;

    procedure TravelName(): Text[100]
    begin
        exit(TravelTok);
    end;

    var
        AccountsPayableDomesticTok: Label 'Accounts Payable, Domestic', MaxLength = 100;
        AccountsPayablePostingTok: Label 'Accounts Payables', MaxLength = 100;
        AdministrativeExpensesTok: Label 'Administrative Expenses', MaxLength = 100;
        AssetsintheformofprepaidexpensesTok: Label 'Assets in the form of prepaid expenses', MaxLength = 100;
        BankAccountKBTok: Label 'Bank Account - KB', MaxLength = 100;
        BankTok: Label 'Bank', MaxLength = 100;
        BanksEuroTok: Label 'Banks Euro', MaxLength = 100;
        BoardAndLodgingTok: Label 'Board and lodging', MaxLength = 100;
        BusinessaccountOperatingDomesticTok: Label 'Business account, Operating, Domestic', MaxLength = 100;
        BusinessEntertainingDeductibleTok: Label 'Business Entertaining, deductible', MaxLength = 100;
        CarAllowanceTok: Label 'Car Allowance', MaxLength = 100;
        CentdiscrepanciesTok: Label 'Cent Discrepancies', MaxLength = 100;
        CurrentLiabilitiesToEmployeesTok: Label 'Current Liabilities to Employees', MaxLength = 100;
        CurrentReceivableFromEmployeesTok: Label 'Current Receivable from Employees', MaxLength = 100;
        DomesticsalesofgoodsandservicesTok: Label 'Domestic Sales of Goods and Services', MaxLength = 100;
        EmployeesPayableTok: Label 'Employees Payable', MaxLength = 100;
        EntertainmentAndPRTok: Label 'Entertainment and PR', MaxLength = 100;
        EntertainmentDeductibleTok: Label 'Entertainment, Deductible', MaxLength = 100;
        EntwinetobaccospiritsTok: Label 'Ent., Wine / Tobacco / Spirits', MaxLength = 100;
        GasolineAndMotorOilTok: Label 'Gasoline and Motor Oil', MaxLength = 100;
        HospitalityDomesticDeductibleAmountTok: Label 'Hospitality domestic deductible amount', MaxLength = 100;
        InternalResourcesTok: Label 'Internal Resources', MaxLength = 100;
        InvoiceRoundingTok: Label 'Invoice Rounding', MaxLength = 100;
        JobSalesAppliedAccountTok: Label 'Job Sales Applied Account', MaxLength = 100;
        KilometerAllowanceTok: Label 'Kilometer allowance', MaxLength = 100;
        MealExpensesAbroadTok: Label 'Meal expenses abroad', MaxLength = 100;
        MealExpensesDomesticTok: Label 'Meal expenses domestic', MaxLength = 100;
        MileagerateTok: Label 'Mileage Rate', MaxLength = 100;
        MiscCostsTok: Label 'Misc. Costs', MaxLength = 100;
        MiscellaneousTok: Label 'Miscellaneous', MaxLength = 100;
        MiscExternalExpensesTok: Label 'Misc. external expenses', MaxLength = 100;
        OtherBankAccountsTok: Label 'Other bank accounts ', MaxLength = 100;
        OtherBusinessExpensesTok: Label 'Other Business Expenses', MaxLength = 100;
        OtherIncidentalRevenueTok: Label 'Other Incidental Revenue', MaxLength = 100;
        OtherTok: Label 'Other', MaxLength = 100;
        OtherOperatingExpensesTok: Label 'Other operating expenses', MaxLength = 100;
        OtherPersonnelCostsTok: Label 'Other Personnel Costs', MaxLength = 100;
        OtherPrepaidExpensesAndAccruedIncomeTok: Label 'Other prepaid expenses and accrued income', MaxLength = 100;
        Otherreceivables1Tok: Label 'Otherreceivables1', MaxLength = 100;
        OtherTravelExpensesTok: Label 'Other travel expenses', MaxLength = 100;
        PayableInvoiceRoundingTok: Label 'Payable Invoice Rounding', MaxLength = 100;
        PayablesToEmployeesTok: Label 'Payables to employees', MaxLength = 100;
        PrepaymentsAccruedCostsTok: Label 'Prepayments - Accrued Costs', MaxLength = 100;
        ProfitOrLossTok: Label 'Profit or Loss', MaxLength = 100;
        RemunerationAdvancesTok: Label 'Remuneration Advances', MaxLength = 100;
        RentalVehiclesTok: Label 'Rental vehicles', MaxLength = 100;
        RepresentationCostsTok: Label 'Representation costs', MaxLength = 100;
        RestaurantdiningTok: Label 'Restaurant Dining', MaxLength = 100;
        RoundingDifferencesPurchaseTok: Label 'Rounding Differences Purchase', MaxLength = 100;
        SaleofResourceTok: Label 'Sale of Resource', MaxLength = 100;
        SaleofResourcesTok: Label 'Sale of Resources', MaxLength = 100;
        SalesGoodsDomesticTok: Label 'Sales goods - domestic', MaxLength = 100;
        SalesInvoiceRoundingTok: Label 'Sales Invoice Rounding', MaxLength = 100;
        SalesofgoodsdomTok: Label 'Salesofgoodsdom', MaxLength = 100;
        SalesOtherJobExpensesTok: Label 'Sales, Other Job Expenses', MaxLength = 100;
        SalesResourcesDomTok: Label 'Sales, Resources - Dom.', MaxLength = 100;
        SalesRevenuesResourcesExportTok: Label 'Sales revenues resources export', MaxLength = 100;
        SettlementAccountCashBankTok: Label 'Settlement account cash bank', MaxLength = 100;
        SubsistenceTok: Label 'Subsitence', MaxLength = 100;
        TransportationThirdPartiesTok: Label 'Transportation third parties', MaxLength = 100;
        TravelCostsCustomerServiceTok: Label 'Travel Costs, Customer Service', MaxLength = 100;
        TravelExpensesTok: Label 'Travel expenses', MaxLength = 100;
        TravelingtradefairsetcTok: Label 'Traveling, Trade Fairs etc.', MaxLength = 100;
        TravelTok: Label 'Travel', MaxLength = 100;
}