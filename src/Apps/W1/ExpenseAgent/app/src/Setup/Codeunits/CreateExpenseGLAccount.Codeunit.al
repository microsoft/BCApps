// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;

codeunit 6971 "Create Expense GL Account"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        CreateGLAccount();
    end;

    var
        ExpenseOtherRefundableLbl: Label 'Misc. external expenses', MaxLength = 100;
        ExpenseOtherRefundableSearchLbl: Label 'Misc. external', MaxLength = 30;
        ExpenseOtherNonRefundableLbl: Label 'Other Incidental Revenue', MaxLength = 100;
        ExpenseOtherNonRefundableSearchLbl: Label 'Incidental revenue', MaxLength = 30;
        ExpenseOtherPrepaymentLbl: Label 'Other prepaid expenses and accrued income', MaxLength = 100;
        ExpenseOtherPrepaymentSearchLbl: Label 'prepaid expenses', MaxLength = 30;
        ExpenseOtherDebitRoundingLbl: Label 'Payable Invoice Rounding', MaxLength = 100;
        ExpenseOtherCreditRoundingLbl: Label 'Payable Invoice Rounding', MaxLength = 100;
        ExpenseRoundingSearchLbl: Label 'Rounding', MaxLength = 30;
        ExpenseTravelRefundableLbl: Label 'Other travel expenses', MaxLength = 100;
        ExpenseTravelRefundableSearchLbl: Label 'travel expense', MaxLength = 30;
        ExpensePerDiemRefundableLbl: Label 'Per-diem travel expenses', MaxLength = 100;
        ExpensePerDiemRefundableSearchLbl: Label 'Per-diem', MaxLength = 30;
        ExpenseMileageRefundableLbl: Label 'Mileage travel expenses', MaxLength = 100;
        ExpenseMileageRefundableSearchLbl: Label 'Mileage', MaxLength = 30;
        ExpenseMealsRefundableLbl: Label 'Meal expenses, deductible', MaxLength = 100;
        ExpenseMealsRefundableSearchLbl: Label 'Meals', MaxLength = 30;
        ExpenseEntertainRefundableLbl: Label 'Business Entertaining, deductible', MaxLength = 100;
        ExpenseEntertainRefundableSearchLbl: Label 'Entertain', MaxLength = 30;
        ExpensePayableCashLbl: Label 'Employees Payable', MaxLength = 100;
        ExpensePrepaymentLbl: Label 'Other prepaid expenses and accrued income', MaxLength = 100;
        ExpensePrepaymentSearchLbl: Label 'prepaid expenses', MaxLength = 30;
        ExpensePayableCardPaidLbl: Label 'Company credit cards account', MaxLength = 100;
        ExpensePayableCardPaidSearchLbl: Label 'credit card', MaxLength = 30;
        ExpensePayableBankPaidLbl: Label 'Other bank accounts', MaxLength = 100;
        ExpensePayableBankPaidSearchLbl: Label 'bank', MaxLength = 30;
        ExpenseCashLbl: Label 'Cash', MaxLength = 100;
        ExpenseCashSearchLbl: Label 'Cash', MaxLength = 30;
        ExpenseTravelRefundableSearchGBLbl: Label 'Travel', MaxLength = 30;
        ExpenseOtherNonRefundableSearchGBLbl: Label 'Other Incidental', MaxLength = 30;
        ExpenseOtherPrepaymentSearchGBLbl: Label 'Other prepaid expenses', MaxLength = 30;
        ExpensePerDiemARefundableLbl: Label 'Meal expenses abroad', MaxLength = 100;
        ExpensePerDiemARefundableSearchLbl: Label 'Meal expenses abroad', MaxLength = 30;
        ExpensePerDiemIRefundableLbl: Label 'Meal expenses domestic', MaxLength = 100;
        ExpensePerDiemIRefundableSearchLbl: Label 'Meal expenses domestic', MaxLength = 30;
        ExpenseMealNonRefundableLbl: Label 'Meal expenses, nondeductible', MaxLength = 100;
        ExpenseMealNonRefundableSearchLbl: Label 'Meal expenses, nondeductible', MaxLength = 30;
        ExpenseOtherEmployeeExpensesLbl: Label 'Other Employee Expenses', MaxLength = 100;
        ExpenseOtherEmployeeExpensesSearchLbl: Label 'Other Employee Expenses', MaxLength = 30;
        ExpenseMiscellaneousLbl: Label 'Miscellaneous', MaxLength = 100;
        ExpenseMiscellaneousSearchLbl: Label 'Miscellaneous', MaxLength = 30;
        ExpenseMiscCostsLbl: Label 'Misc. Costs', MaxLength = 100;
        ExpenseMiscCostsSearchLbl: Label 'Misc. Costs', MaxLength = 30;
        ExpenseAdministrativeExpensesLbl: Label 'Administrative Expenses', MaxLength = 100;
        ExpenseAdministrativeExpensesSearchLbl: Label 'Administrative Expenses', MaxLength = 30;
        ExpenseOtherOperatingExpensesLbl: Label 'Other operating expenses', MaxLength = 100;
        ExpenseOtherOperatingExpensesSearchLbl: Label 'Other operating expenses', MaxLength = 30;
        ExpenseOtherTravelExpensesLbl: Label 'Other Travel Expenses', MaxLength = 100;
        ExpenseOtherTravelExpensesSearchLbl: Label 'Other Travel Expenses', MaxLength = 30;
        ExpenseTravelLbl: Label 'Travel', MaxLength = 100;
        ExpenseTravelSearchLbl: Label 'Travel', MaxLength = 30;
        ExpenseTravelCostsCustServiceLbl: Label 'Travel Costs, Customer Service', MaxLength = 100;
        ExpenseTravelCostsCustServiceSearchLbl: Label 'Travel Costs, Customer Service', MaxLength = 30;
        ExpenseTravelExpensesLbl: Label 'Travel expenses', MaxLength = 100;
        ExpenseTravelExpensesSearchLbl: Label 'Travel expenses', MaxLength = 30;
        ExpensePerDiemAllowanceLbl: Label 'Per Diem Allowance', MaxLength = 100;
        ExpensePerDiemAllowanceSearchLbl: Label 'Per Diem Allowance', MaxLength = 30;
        ExpensePerDiemAllowanceHyphenLbl: Label 'Per-Diem Allowance', MaxLength = 100;
        ExpensePerDiemAllowanceHyphenSearchLbl: Label 'Per-Diem Allowance', MaxLength = 30;
        ExpenseSubsistenceLbl: Label 'Subsitence', MaxLength = 100;
        ExpenseSubsistenceSearchLbl: Label 'Subsitence', MaxLength = 30;
        ExpenseMileageAllowanceLbl: Label 'Mileage Allowance', MaxLength = 100;
        ExpenseMileageAllowanceSearchLbl: Label 'Mileage Allowance', MaxLength = 30;
        ExpenseMileageReimbursementLbl: Label 'Mileage Reimbursement', MaxLength = 100;
        ExpenseMileageReimbursementSearchLbl: Label 'Mileage Reimbursement', MaxLength = 30;
        ExpenseGasolineMotorOilLbl: Label 'Gasoline and Motor Oil', MaxLength = 100;
        ExpenseGasolineMotorOilSearchLbl: Label 'Gasoline and Motor Oil', MaxLength = 30;
        ExpenseCarAllowanceLbl: Label 'Car Allowance', MaxLength = 100;
        ExpenseCarAllowanceSearchLbl: Label 'Car Allowance', MaxLength = 30;
        ExpenseMealsHospitalityLbl: Label 'Meals and Hospitality Expenses', MaxLength = 100;
        ExpenseMealsHospitalitySearchLbl: Label 'Meals and Hospitality Expenses', MaxLength = 30;
        ExpenseBusinessMealsLbl: Label 'Business Meals', MaxLength = 100;
        ExpenseBusinessMealsSearchLbl: Label 'Business Meals', MaxLength = 30;
        ExpenseBusinessMealExpensesLbl: Label 'Business Meal Expenses', MaxLength = 100;
        ExpenseBusinessMealExpensesSearchLbl: Label 'Business Meal Expenses', MaxLength = 30;
        ExpenseBoardAndLodgingLbl: Label 'Board and lodging', MaxLength = 100;
        ExpenseBoardAndLodgingSearchLbl: Label 'Board and lodging', MaxLength = 30;
        ExpenseEntertainmentAndPRLbl: Label 'Entertainment and PR', MaxLength = 100;
        ExpenseEntertainmentAndPRSearchLbl: Label 'Entertainment and PR', MaxLength = 30;
        ExpenseEntertainmentDeductibleLbl: Label 'Entertainment, Deductible', MaxLength = 100;
        ExpenseEntertainmentDeductibleSearchLbl: Label 'Entertainment, Deductible', MaxLength = 30;
        ExpenseBusinessMealsEntertainLbl: Label 'Business Meals and Entertainment', MaxLength = 100;
        ExpenseBusinessMealsEntertainSearchLbl: Label 'Business Meals and Entertain', MaxLength = 30;
        ExpenseEntertainmentExpensesLbl: Label 'Entertainment Expenses', MaxLength = 100;
        ExpenseEntertainmentExpensesSearchLbl: Label 'Entertainment Expenses', MaxLength = 30;
        ExpenseRepresentationCostsLbl: Label 'Representation costs', MaxLength = 100;
        ExpenseRepresentationCostsSearchLbl: Label 'Representation costs', MaxLength = 30;
        ExpenseNonRefundableEmpLbl: Label 'Non-Refundable Employee Expenses', MaxLength = 100;
        ExpenseNonRefundableEmpSearchLbl: Label 'Non-Refundable Employee', MaxLength = 30;
        ExpenseNonDeductibleEmpLbl: Label 'Non-Deductible Employee Expenses', MaxLength = 100;
        ExpenseNonDeductibleEmpSearchLbl: Label 'Non-Deductible Employee', MaxLength = 30;
        ExpenseOtherPersonnelCostsLbl: Label 'Other Personnel Costs', MaxLength = 100;
        ExpenseOtherPersonnelCostsSearchLbl: Label 'Other Personnel Costs', MaxLength = 30;
        ExpenseEmpExpenseAdvancesLbl: Label 'Employee Expense Advances', MaxLength = 100;
        ExpenseEmpExpenseAdvancesSearchLbl: Label 'Employee Expense Advances', MaxLength = 30;
        ExpenseEmpTravelAdvancesLbl: Label 'Employee Travel Advances', MaxLength = 100;
        ExpenseEmpTravelAdvancesSearchLbl: Label 'Employee Travel Advances', MaxLength = 30;
        ExpenseEmpAdvancesPrepaymentsLbl: Label 'Employee Advances and Expense Prepayments', MaxLength = 100;
        ExpenseEmpAdvancesPrepaymentsSearchLbl: Label 'Employee Advances and Expense', MaxLength = 30;
        ExpenseEmpExpensePrepaymentsLbl: Label 'Employee Expense Prepayments', MaxLength = 100;
        ExpenseEmpExpensePrepaymentsSearchLbl: Label 'Employee Expense Prepayments', MaxLength = 30;
        ExpenseCurrentReceivableEmpLbl: Label 'Current Receivable from Employees', MaxLength = 100;
        ExpenseCurrentReceivableEmpSearchLbl: Label 'Current Receivable', MaxLength = 30;
        ExpenseOtherreceivables1Lbl: Label 'Otherreceivables1', MaxLength = 100;
        ExpenseOtherreceivables1SearchLbl: Label 'Otherreceivables1', MaxLength = 30;
        ExpensePayablesToEmployeesLbl: Label 'Payables to employees', MaxLength = 100;
        ExpenseCurrentLiabilitiesEmpLbl: Label 'Current Liabilities to Employees', MaxLength = 100;
        ExpenseEmpExpReimbursementsPayableLbl: Label 'Employee Expense Reimbursements Payable', MaxLength = 100;
        ExpenseEmpExpReimbursementPayableLbl: Label 'Employee Expense Reimbursement Payable', MaxLength = 100;
        ExpenseEmpExpPayableCashLbl: Label 'Employee Expense Payable - Cash Reimbursement', MaxLength = 100;
        ExpenseRoundingDifferencesLbl: Label 'Expense Rounding Differences', MaxLength = 100;
        ExpenseRoundingDifferencesSearchLbl: Label 'Expense Rounding Differences', MaxLength = 30;
        ExpenseInvoiceRoundingLbl: Label 'Invoice Rounding', MaxLength = 100;
        ExpenseInvoiceRoundingSearchLbl: Label 'Invoice Rounding', MaxLength = 30;
        ExpenseRoundingDiffPurchaseLbl: Label 'Rounding Differences Purchase', MaxLength = 100;
        ExpenseRoundingDiffPurchaseSearchLbl: Label 'Rounding Differences Purchase', MaxLength = 30;
        ExpenseCompanyPaidExpClearingLbl: Label 'Company Paid Expense Clearing', MaxLength = 100;
        ExpenseCompanyPaidExpClearingSearchLbl: Label 'Company Paid Expense Clearing', MaxLength = 30;
        ExpenseCompanyPaidExpClearHyphenLbl: Label 'Company-Paid Expense Clearing', MaxLength = 100;
        ExpenseCompanyPaidExpClearHyphenSearchLbl: Label 'Company-Paid Expense Clearing', MaxLength = 30;
        ExpenseBankPaidExpClearingLbl: Label 'Bank-Paid Expense Clearing Account', MaxLength = 100;
        ExpenseBankPaidExpClearingSearchLbl: Label 'Bank-Paid Expense Clearing', MaxLength = 30;
        ExpenseEmpExpPayableCompPaidLbl: Label 'Employee Expense Payable - Company Paid', MaxLength = 100;
        ExpenseEmpExpPayableCompPaidSearchLbl: Label 'Payable - Company Paid', MaxLength = 30;
        ExpenseBankAccountKBLbl: Label 'Bank Account - KB', MaxLength = 100;
        ExpenseBankAccountKBSearchLbl: Label 'Bank Account - KB', MaxLength = 30;
        ExpenseCorporateCardExpClearingLbl: Label 'Corporate Card Expense Clearing', MaxLength = 100;
        ExpenseCorporateCardExpClearingSearchLbl: Label 'Corporate Card Expense', MaxLength = 30;
        ExpenseCompanyCardExpPayableLbl: Label 'Company Card Expenses Payable', MaxLength = 100;
        ExpenseCompanyCardExpPayableSearchLbl: Label 'Company Card Expenses Payable', MaxLength = 30;
        ExpenseCompanyCardExpClearingLbl: Label 'Company Card Expense Clearing', MaxLength = 100;
        ExpenseCompanyCardExpClearingSearchLbl: Label 'Company Card Expense Clearing', MaxLength = 30;
        ExpenseCorporateCardExpPayableLbl: Label 'Corporate Card Expense Payable', MaxLength = 100;
        ExpenseCorporateCardExpPayableSearchLbl: Label 'Corporate Card Expense Payable', MaxLength = 30;
        ExpenseEmpExpPayableCompCardLbl: Label 'Employee Expense Payable - Company Card', MaxLength = 100;
        ExpenseEmpExpPayableCompCardSearchLbl: Label 'Payable - Company Card', MaxLength = 30;
        ExpenseOtherBusinessExpensesLbl: Label 'Other Business Expenses', MaxLength = 100;
        ExpenseOtherBusinessExpensesSearchLbl: Label 'Other Business Expenses', MaxLength = 30;
        ExpenseOtherNondeductTravelLbl: Label 'Other nondeductible travel expenses', MaxLength = 100;
        ExpenseOtherNondeductTravelSearchLbl: Label 'Other nondeductible travel', MaxLength = 30;
        ExpenseExpensesPrepaymentsLbl: Label 'Expenses Prepayments', MaxLength = 100;
        ExpenseExpensesPrepaymentsSearchLbl: Label 'Expenses Prepayments', MaxLength = 30;
        ExpenseRoundingExpensesOperatingLbl: Label 'Rounding Expenses Operating', MaxLength = 100;
        ExpenseRemunerationAdvancesLbl: Label 'Remuneration Advances', MaxLength = 100;
        ExpenseBanksEuroLbl: Label 'Banks Euro', MaxLength = 100;
        ExpenseProfitLossLbl: Label 'Profit or Loss', MaxLength = 100;
        ExpenseProfitLossSearchLbl: Label 'Profit or Loss', MaxLength = 30;
        ExpenseOtherExternalCostsLbl: Label 'Other external costs', MaxLength = 100;
        ExpenseOtherExternalCostsSearchLbl: Label 'Other external', MaxLength = 30;
        ExpenseTravelingTradeFairsLbl: Label 'Traveling, Trade Fairs etc.', MaxLength = 100;
        ExpenseTravelAllowancesPerDiemLbl: Label 'Travel allowances per diem', MaxLength = 100;
        ExpensePerDiemLowerSearchLbl: Label 'per diem', MaxLength = 30;
        ExpenseMileageRateLbl: Label 'Mileage Rate', MaxLength = 100;
        ExpenseRestaurantDiningLbl: Label 'Restaurant Dining', MaxLength = 100;
        ExpenseRestaurantSearchLbl: Label 'Restaurant', MaxLength = 30;
        ExpenseEntWineTobaccoSpiritsLbl: Label 'Ent., Wine / Tobacco / Spirits', MaxLength = 100;
        ExpenseNonDeductibleTravelLbl: Label 'Non-deductible travel expenses', MaxLength = 100;
        ExpenseNonDeductibleTravelSearchLbl: Label 'Non-deductible travel', MaxLength = 30;
        ExpensePrepaymentsAccruedCostsLbl: Label 'Prepayments - Accrued Costs', MaxLength = 100;
        ExpensePrepaymentsAccruedSearchLbl: Label 'Accrued Costs', MaxLength = 30;
        ExpenseCentDiscrepanciesLbl: Label 'Cent Discrepancies', MaxLength = 100;
        ExpenseAccountsPayablesLbl: Label 'Accounts Payables', MaxLength = 100;
        ExpenseBankLbl: Label 'Bank', MaxLength = 100;
        ExpenseCompanyCreditCardsLbl: Label 'Company credit cards', MaxLength = 100;
        ExpenseAssetsPrepaidLbl: Label 'Assets in the form of prepaid expenses', MaxLength = 100;
        ExpenseSalesInvoiceRoundingLbl: Label 'Sales Invoice Rounding', MaxLength = 100;
        ExpenseBusinessAccountOperatingLbl: Label 'Business account, Operating, Domestic', MaxLength = 100;
        ExpenseCompanyCreditCardClearingLbl: Label 'Company credit card clearing account', MaxLength = 100;
        ExpenseVacationCompPayableLbl: Label 'Vacation Compensation Payable', MaxLength = 100;
        ExpenseBankCheckingLbl: Label 'Bank, Checking', MaxLength = 100;
        ExpensePrepaymentBeginLbl: Label 'Employee prepayments', MaxLength = 100;
        ExpensePrepaymentTotalLbl: Label 'Employee Prepayments, Total', MaxLength = 100;
        ExpenseBusinessEntertainNondeductLbl: Label 'Business Entertaining, nondeductible', MaxLength = 100;
        ExpenseBusinessEntertainNondeductSearchLbl: Label 'Business Entertaining', MaxLength = 30;
        ExpenseFinanceChargesVendorsLbl: Label 'Finance Charges to Vendors', MaxLength = 100;
        ExpenseFinanceChargesVendorsSearchLbl: Label 'Finance Charges to Vendors', MaxLength = 30;
        ExpenseEmployeePrepaymentsExpLbl: Label 'Employee Prepayments, Expenses', MaxLength = 100;
        ExpenseEmployeePrepaymentsExpSearchLbl: Label 'Employee Prepayments, Expenses', MaxLength = 30;
        ExpenseEmployeePrepaymentsSearchLbl: Label 'Employee Prepayments', MaxLength = 30;
        ExpenseBankLCYLbl: Label 'Bank, LCY', MaxLength = 100;
        ExpenseMiscExternalNondeductibleLbl: Label 'Misc. external expenses, nondeductible', MaxLength = 100;
        ExpenseAccountsPayableDomesticLbl: Label 'Accounts Payable, Domestic', MaxLength = 100;
        ExpenseTransportThirdPartiesLbl: Label 'Transportation third parties', MaxLength = 100;
        ExpenseTransportThirdPartiesSearchLbl: Label 'Transportation third', MaxLength = 30;
        ExpenseApplicationRoundingLbl: Label 'Application Rounding', MaxLength = 100;
        ExpenseCreditCardClearingSearchLbl: Label 'credit card clearing', MaxLength = 30;


    local procedure CreateGLAccount()
    var
        GLAccountIndent: Codeunit "G/L Account-Indent";
        IsHandled: Boolean;
        SubCategory: Text[80];
    begin
        OnBeforeCreateGLAccount(IsHandled);
        if IsHandled then
            exit;

        if GetCountryCode() = 'ES' then
            InsertGLAccount(ExpenseProfitLossAccountNo(), ExpenseProfitLossLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Equity, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseOtherRefundableDebitAccountNo(), ExpenseOtherRefundableAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseTravelRefundableDebitAccountNo(), ExpenseTravelRefundableAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        if GetCountryCode() = 'AT' then begin
            InsertGLAccount(ExpensePerDiemARefundableDebitAccountNo(), ExpensePerDiemARefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
            InsertGLAccount(ExpensePerDiemIRefundableDebitAccountNo(), ExpensePerDiemIRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        end else
            InsertGLAccount(ExpensePerDiemRefundableDebitAccountNo(), ExpensePerDiemRefundableAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseMileageRefundableDebitAccountNo(), ExpenseMileageRefundableAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseEntertainRefundableDebitAccountNo(), ExpenseEntertainRefundableAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseMealsRefundableDebitAccountNo(), ExpenseMealsRefundableAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        if GetCountryCode() in ['AT', 'DE', 'DK', 'ES', 'FR'] then
            InsertGLAccount(ExpenseMealNonRefundableDebitAccountNo(), ExpenseMealNonRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        InsertGLAccount(ExpenseNonRefundableDebitAccountNo(), ExpenseNonRefundableAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        if GetCountryCode() in ['CA', 'NZ'] then begin
            SubCategory := Format(Enum::"G/L Account Category"::Expense, 80);
            InsertGLAccount(ExpensePrepaymentBeginAccountNo(), ExpensePrepaymentBeginLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::"Begin-Total", '', '', '', 0, '', Enum::"G/L Account Type"::"Begin-Total", '', '', false, false, false);
        end;
        InsertGLAccount(ExpensePrepaymentDebitAccountNo(), ExpensePrepaymentDebitAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        if GetCountryCode() in ['CA', 'NZ'] then
            InsertGLAccount(ExpensePrepaymentTotalAccountNo(), ExpensePrepaymentTotalLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::"End-Total", '', '', '', 0, ExpensePrepaymentBeginAccountNo() + '..' + ExpensePrepaymentTotalAccountNo(), Enum::"G/L Account Type"::"End-Total", '', '', false, false, false);
        InsertGLAccount(ExpenseDebitRoundingAccountNo(), ExpenseDebitRoundingAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseCreditRoundingAccountNo(), ExpenseCreditRoundingAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        InsertGLAccount(ExpenseReportPayableAccountNo(), ExpenseReportPayableAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Liabilities, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseReportPrepaymentAccountNo(), ExpenseReportPrepaymentAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpensePayableCardPaidAccountNo(), ExpensePayableCardPaidAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpensePayableBankPaidAccountNo(), ExpensePayableBankPaidAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        if GetCountryCode() = 'ES' then
            UpdateIncomeStatementBalanceAccount()
        else
            if GetCountryCode() <> '' then
                GLAccountIndent.Indent();
    end;

    internal procedure InsertGLAccount(AccountNo: Code[20]; Name: Text[100]; IncomeOrBalance: Enum "G/L Account Income/Balance"; AccountCategory: Enum "G/L Account Category"; AccountSubCategory: Text[80]; AccountType: Enum "G/L Account Type"; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; TaxGroup: Code[20]; NoOfBlankLines: Integer; Totaling: Text[250]; GenPostingType: Enum "General Posting Type"; VATGenPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; DirectPosting: Boolean; ReconciliationAccount: Boolean; NewPage: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNo) then
            exit;

        GLAccount.Validate("No.", AccountNo);
        GLAccount.Validate(Name, Name);

        case IncomeOrBalance of
            IncomeOrBalance::"Income Statement":
                GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
            IncomeOrBalance::"Balance Sheet":
                GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        end;

        ValidateAccountCategory(GLAccount, AccountCategory, AccountSubCategory);

        GLAccount.Validate("Account Type", AccountType);
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then
            GLAccount.Validate("Direct Posting", DirectPosting);

        GLAccount.Validate("No. of Blank Lines", NoOfBlankLines);

        if Totaling <> '' then
            GLAccount.Validate(Totaling, Totaling);
        if GenPostingType <> GenPostingType::" " then
            GLAccount.Validate("Gen. Posting Type", GenPostingType);
        if (VATGenPostingGroup <> '') then
            GLAccount.Validate("VAT Bus. Posting Group", VATGenPostingGroup);
        if (VATProdPostingGroup <> '') then
            GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);

        GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("Reconciliation Account", ReconciliationAccount);
        GLAccount.Validate("New Page", NewPage);

        if GenProdPostingGroup <> '' then
            GLAccount.Validate("Tax Group Code", TaxGroup);

        GLAccount.Insert(true);
    end;

    local procedure ValidateAccountCategory(var GLAccount: Record "G/L Account"; Category: Enum "G/L Account Category"; SubCategory: Text[80])
    begin
        if Category <> Enum::"G/L Account Category"::" " then begin
            GLAccount.Validate("Account Category", Category);

            if SubCategory = '' then
                GLAccount.Validate("Account Subcategory Entry No.", 0)
            else
                GLAccount.ValidateAccountSubCategory(SubCategory);
        end else
            GLAccount.Validate("Account Category", Enum::"G/L Account Category"::" ");
    end;

    local procedure UpdateIncomeStatementBalanceAccount()
    var
        ProfitLossAccountNo: Code[20];
    begin
        ProfitLossAccountNo := ExpenseProfitLossAccountNo();

        UpdateIncomeStmtBalAcc(ExpenseOtherRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseTravelRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpensePerDiemRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseMileageRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseEntertainRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseMealsRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseMealNonRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseNonRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpensePrepaymentDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseDebitRoundingAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseCreditRoundingAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseReportPayableAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseReportPrepaymentAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpensePayableCardPaidAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpensePayableBankPaidAccountNo(), ProfitLossAccountNo);
    end;

    local procedure UpdateIncomeStmtBalAcc(No: Code[20]; IncomeStmtBalAcc: Code[20])
    var
        GLAccount: Record "G/L Account";
        GLAccountRecRef: RecordRef;
        IncomeStmtBalAccFieldRef: FieldRef;
    begin
        if not GLAccount.Get(No) then
            exit;

        GLAccountRecRef.GetTable(GLAccount);
        if not GLAccountRecRef.FieldExist(ESIncomeStmtBalAccFieldNo()) then
            exit;

        IncomeStmtBalAccFieldRef := GLAccountRecRef.Field(ESIncomeStmtBalAccFieldNo());
        IncomeStmtBalAccFieldRef.Validate(IncomeStmtBalAcc);
        GLAccountRecRef.Modify();
    end;

    local procedure ESIncomeStmtBalAccFieldNo(): Integer
    begin
        exit(10700);
    end;

    internal procedure ExpenseOtherRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherRefundableAccountName(), ExpenseOtherRefundableSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'CH':
                exit('6780');
            'CZ':
                exit('548100');
            'IT':
                exit('8640');
            'US':
                exit('68280');
            'AU':
                exit('6236');
            'CA':
                exit('67430');
            'DE':
                exit('6300');
            'DK':
                exit('05699');
            'ES':
                exit('6290003');
            'FR':
                exit('625180');
            'NZ':
                exit('8660');
            'AT':
                exit('7740');
            'BE':
                exit('623100');
            'FI':
                exit('6166');
            'NL':
                exit('4291');
            'NO':
                exit('9135');
        end;
        exit('31540');
    end;

    internal procedure ExpenseTravelRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseTravelRefundableAccountName(), ExpenseTravelRefundableSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'BE':
                exit('613900');
            'CH':
                exit('6640');
            'CZ':
                exit('512100');
            'IT':
                exit('8430');
            'NL':
                exit('3464');
            'US':
                exit('62340');
            'AU':
                exit('6249');
            'CA':
                exit('61340');
            'DE':
                exit('6650');
            'DK':
                exit('03650');
            'ES':
                exit('6291001');
            'FR':
                exit('625100');
            'NZ':
                exit('8430');
            'AT':
                exit('7310');
            'FI':
                exit('6165');
            'NO':
                exit('8430');
        end;
        exit('30540');
    end;

    internal procedure ExpensePerDiemRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePerDiemRefundableAccountName(), ExpensePerDiemRefundableSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'US':
                exit('62350');
            'AU':
                exit('6246');
            'CA':
                exit('61310');
            'DE':
                exit('6664');
            'DK':
                exit('03652');
            'ES':
                exit('6291002');
            'FR':
                exit('625110');
            'NZ':
                exit('8431');
            'BE':
                exit('613950');
            'CH':
                exit('5822');
            'CZ':
                exit('512300');
            'FI':
                exit('6163');
            'IT':
                exit('8431');
            'NL':
                exit('3466');
            'NO':
                exit('9170');
        end;
        exit('30550');
    end;

    internal procedure ExpensePerDiemARefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePerDiemARefundableLbl, ExpensePerDiemARefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7360');
    end;

    internal procedure ExpensePerDiemIRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePerDiemIRefundableLbl, ExpensePerDiemIRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7350');
    end;

    internal procedure ExpenseMealNonRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMealNonRefundableLbl, ExpenseMealNonRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'DE':
                exit('6662');
            'DK':
                exit('03661');
            'ES':
                exit('6292002');
            'FR':
                exit('625210');
        end;
        exit('7692');
    end;

    internal procedure ExpenseMileageRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMileageRefundableAccountName(), ExpenseMileageRefundableSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'IT':
                exit('8510');
            'US':
                exit('62360');
            'AU':
                exit('6247');
            'CA':
                exit('61320');
            'DE':
                exit('6658');
            'DK':
                exit('03180');
            'ES':
                exit('6291003');
            'FR':
                exit('625120');
            'NZ':
                exit('8432');
            'AT':
                exit('7340');
            'BE':
                exit('613940');
            'CH':
                exit('5821');
            'CZ':
                exit('512200');
            'FI':
                exit('6162');
            'NL':
                exit('3465');
            'NO':
                exit('8910');
        end;
        exit('30560');
    end;

    internal procedure ExpenseMealsRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMealsRefundableAccountName(), ExpenseMealsRefundableSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'IT':
                exit('8420');
            'NL':
                exit('3463');
            'US':
                exit('62370');
            'AU':
                exit('6248');
            'CA':
                exit('61330');
            'DE':
                exit('6660');
            'DK':
                exit('03660');
            'ES':
                exit('6292001');
            'FR':
                exit('625200');
            'NZ':
                exit('8433');
            'AT':
                exit('7691');
            'BE':
                exit('613910');
            'CH':
                exit('5841');
            'CZ':
                exit('513200');
            'FI':
                exit('6161');
            'NO':
                exit('8450');
        end;
        exit('30535');
    end;

    internal procedure ExpenseEntertainRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseEntertainRefundableAccountName(), ExpenseEntertainRefundableSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'BE':
                exit('614500');
            'CZ':
                exit('513100');
            'IT':
                exit('8420');
            'US':
                exit('63420');
            'AU':
                exit('6235');
            'CA':
                exit('61200');
            'DE':
                exit('6640');
            'DK':
                exit('03630');
            'ES':
                exit('6293001');
            'FR':
                exit('625700');
            'NZ':
                exit('8420');
            'AT':
                exit('7680');
            'CH':
                exit('5840');
            'FI':
                exit('6160');
            'NL':
                exit('3564');
            'NO':
                exit('8450');
        end;
        exit('30820');
    end;

    internal procedure ExpenseNonRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseNonRefundableAccountName(), ExpenseNonRefundableSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'CH':
                exit('5830');
            'US':
                exit('40390');
            'AU':
                exit('7240');
            'CA':
                exit('71900');
            'DE':
                exit('6650');
            'DK':
                exit('03655');
            'ES':
                exit('6299001');
            'FR':
                exit('625290');
            'NZ':
                exit('9240');
            'AT':
                exit('7745');
            'BE':
                exit('643100');
            'CZ':
                exit('548200');
            'FI':
                exit('6167');
            'IT':
                exit('8911');
            'NL':
                exit('4292');
            'NO':
                exit('5964');
        end;
        exit('10390');
    end;

    internal procedure ExpensePrepaymentDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePrepaymentDebitAccountName(), ExpensePrepaymentDebitSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'FI':
                exit('1720');
            'NL':
                exit('0710');
            'US':
                exit('16600');
            'AU':
                exit('1512');
            'CA':
                exit('13610');
            'DE':
                exit('1900');
            'DK':
                exit('26400');
            'ES':
                exit('4800001');
            'FR':
                exit('486200');
            'NZ':
                exit('2510');
            'AT':
                exit('2770');
            'BE':
                exit('416000');
            'CH':
                exit('1305');
            'CZ':
                exit('335100');
            'IT':
                exit('2341');
            'NO':
                exit('5963');
        end;
        exit('76600');
    end;

    internal procedure ExpenseDebitRoundingAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseDebitRoundingAccountName(), ExpenseRoundingSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'CH':
                exit('4908');
            'IT':
                exit('9140');
            'NL':
                exit('3930');
            'US':
                exit('67300');
            'AU':
                exit('4756');
            'CA':
                exit('47400');
            'DE':
                exit('7500');
            'DK':
                exit('07570');
            'ES':
                exit('6298001');
            'FR':
                exit('658600');
            'NZ':
                exit('9140');
            'AT':
                exit('8070');
            'BE':
                exit('655100');
            'CZ':
                exit('548900');
            'FI':
                exit('6168');
            'NO':
                exit('5965');
        end;
        exit('31330');
    end;

    internal procedure ExpenseCreditRoundingAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseCreditRoundingAccountName(), ExpenseRoundingSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'CH':
                exit('4908');
            'IT':
                exit('9140');
            'NL':
                exit('3930');
            'US':
                exit('67300');
            'AU':
                exit('4756');
            'CA':
                exit('47400');
            'DE':
                exit('7500');
            'DK':
                exit('07570');
            'ES':
                exit('6298001');
            'FR':
                exit('658600');
            'NZ':
                exit('9140');
            'AT':
                exit('8070');
            'BE':
                exit('655100');
            'CZ':
                exit('548900');
            'FI':
                exit('6168');
            'NO':
                exit('5965');
        end;
        exit('31330');
    end;

    internal procedure ExpenseReportPayableAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Liabilities, ExpenseReportPayableAccountName());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'BE':
                exit('457000');
            'CZ':
                exit('333100');
            'FI':
                exit('2914');
            'NL':
                exit('1520');
            'US':
                exit('22100');
            'AU':
                exit('2378');
            'CA':
                exit('23850');
            'DE':
                exit('4150');
            'DK':
                exit('25100');
            'ES':
                exit('4600001');
            'FR':
                exit('438300');
            'NZ':
                exit('5850');
            'AT':
                exit('3680');
            'CH':
                exit('2270');
            'IT':
                exit('5851');
            'NO':
                exit('5960');
        end;
        exit('5850');
    end;

    internal procedure ExpenseReportPrepaymentAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        if GetCountryCode() in ['GB', 'US'] then begin
            ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Assets, ExpenseCashLbl, ExpenseCashSearchLbl);
            if ExistingAccNo <> '' then
                exit(ExistingAccNo);
            case GetCountryCode() of
                'GB':
                    exit('78100');
                'US':
                    exit('18100');
            end;
        end;

        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Assets, ExpenseReportPrepaymentAccountName(), ExpenseReportPrepaymentSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'FI':
                exit('1720');
            'NL':
                exit('0710');
            'AU':
                exit('1512');
            'CA':
                exit('13610');
            'DE':
                exit('1900');
            'DK':
                exit('26400');
            'ES':
                exit('4800001');
            'FR':
                exit('486200');
            'NZ':
                exit('2510');
            'AT':
                exit('2770');
            'BE':
                exit('416000');
            'CH':
                exit('1305');
            'CZ':
                exit('335100');
            'IT':
                exit('2341');
            'NO':
                exit('5963');
        end;
        exit('76600');
    end;

    local procedure ExpenseReportPrepaymentAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'GB', 'US':
                exit(ExpenseCashLbl);
            'CZ', 'CH':
                exit(ExpenseEmpExpenseAdvancesLbl);
            'BE':
                exit(ExpenseEmpTravelAdvancesLbl);
            'IT':
                exit(ExpenseEmpAdvancesPrepaymentsLbl);
            'NO':
                exit(ExpenseEmpExpensePrepaymentsLbl);
            'NL':
                exit(ExpenseCurrentReceivableEmpLbl);
            'FI':
                exit(ExpenseOtherreceivables1Lbl);
            'AU':
                exit(ExpenseEmployeePrepaymentsExpLbl);
            'CA':
                exit(ExpenseEmployeePrepaymentsExpLbl);
            'NZ':
                exit(ExpenseEmployeePrepaymentsExpLbl);
            'DE':
                exit(ExpenseAssetsPrepaidLbl);
            'DK':
                exit(ExpensePrepaymentsAccruedCostsLbl);
            'ES':
                exit(ExpenseExpensesPrepaymentsLbl);
        end;
        exit(ExpensePrepaymentLbl);
    end;

    local procedure ExpenseReportPrepaymentSearch(): Text[30]
    begin
        case GetCountryCode() of
            'CZ', 'CH':
                exit(ExpenseEmpExpenseAdvancesSearchLbl);
            'BE':
                exit(ExpenseEmpTravelAdvancesSearchLbl);
            'IT':
                exit(ExpenseEmpAdvancesPrepaymentsSearchLbl);
            'NO':
                exit(ExpenseEmpExpensePrepaymentsSearchLbl);
            'NL':
                exit(ExpenseCurrentReceivableEmpSearchLbl);
            'FI':
                exit(ExpenseOtherreceivables1SearchLbl);
            'AU':
                exit(ExpenseEmployeePrepaymentsSearchLbl);
            'CA':
                exit(ExpenseEmployeePrepaymentsSearchLbl);
            'NZ':
                exit(ExpenseEmployeePrepaymentsSearchLbl);
            'DK':
                exit(ExpensePrepaymentsAccruedSearchLbl);
            'ES':
                exit(ExpenseExpensesPrepaymentsSearchLbl);
        end;
        exit(ExpensePrepaymentSearchLbl);
    end;

    local procedure ExpenseOtherRefundableAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'NL', 'BE', 'FI':
                exit(ExpenseOtherEmployeeExpensesLbl);
            'IT':
                exit(ExpenseMiscellaneousLbl);
            'CH':
                exit(ExpenseMiscCostsLbl);
            'NO':
                exit(ExpenseAdministrativeExpensesLbl);
            'CZ':
                exit(ExpenseOtherOperatingExpensesLbl);
            'US':
                exit(ExpenseMiscExternalNondeductibleLbl);
            'AU':
                exit(ExpenseBusinessEntertainNondeductLbl);
            'CA':
                exit(ExpenseMiscExternalNondeductibleLbl);
            'DK':
                exit(ExpenseOtherExternalCostsLbl);
            'ES':
                exit(ExpenseOtherBusinessExpensesLbl);
        end;
        exit(ExpenseOtherRefundableLbl);
    end;

    local procedure ExpenseOtherRefundableSearch(): Text[30]
    begin
        case GetCountryCode() of
            'NL', 'BE', 'FI':
                exit(ExpenseOtherEmployeeExpensesSearchLbl);
            'IT':
                exit(ExpenseMiscellaneousSearchLbl);
            'CH':
                exit(ExpenseMiscCostsSearchLbl);
            'NO':
                exit(ExpenseAdministrativeExpensesSearchLbl);
            'CZ':
                exit(ExpenseOtherOperatingExpensesSearchLbl);
            'AU':
                exit(ExpenseBusinessEntertainNondeductSearchLbl);
            'DK':
                exit(ExpenseOtherExternalCostsSearchLbl);
            'ES':
                exit(ExpenseOtherBusinessExpensesSearchLbl);
        end;
        exit(ExpenseOtherRefundableSearchLbl);
    end;

    local procedure ExpenseTravelRefundableAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'AT':
                exit(ExpenseTransportThirdPartiesLbl);
            'BE', 'IT', 'NO', 'FR':
                exit(ExpenseTravelLbl);
            'FI':
                exit(ExpenseOtherTravelExpensesLbl);
            'CH':
                exit(ExpenseTravelCostsCustServiceLbl);
            'CZ':
                exit(ExpenseTravelExpensesLbl);
            'DK':
                exit(ExpenseTravelingTradeFairsLbl);
            'NZ':
                exit(ExpenseTravelLbl);
            'ES':
                exit(ExpenseTravelExpensesLbl);
        end;
        exit(ExpenseTravelRefundableLbl);
    end;

    local procedure ExpenseTravelRefundableSearch(): Text[30]
    begin
        case GetCountryCode() of
            'AT':
                exit(ExpenseTransportThirdPartiesSearchLbl);
            'GB', 'US':
                exit(ExpenseTravelRefundableSearchGBLbl);
            'BE', 'IT', 'NO', 'FR':
                exit(ExpenseTravelSearchLbl);
            'FI':
                exit(ExpenseOtherTravelExpensesSearchLbl);
            'CH':
                exit(ExpenseTravelCostsCustServiceSearchLbl);
            'CZ':
                exit(ExpenseTravelExpensesSearchLbl);
            'AU':
                exit(ExpenseTravelRefundableSearchGBLbl);
            'CA':
                exit(ExpenseTravelRefundableSearchGBLbl);
            'DE':
                exit(ExpenseTravelRefundableSearchGBLbl);
            'DK':
                exit(ExpenseTravelRefundableSearchGBLbl);
            'ES':
                exit(ExpenseTravelRefundableSearchGBLbl);
        end;
        exit(ExpenseTravelRefundableSearchLbl);
    end;

    local procedure ExpensePerDiemRefundableAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'CZ', 'NL', 'CH', 'IT':
                exit(ExpensePerDiemAllowanceLbl);
            'BE', 'FI':
                exit(ExpensePerDiemAllowanceHyphenLbl);
            'NO':
                exit(ExpenseSubsistenceLbl);
            'DK':
                exit(ExpenseTravelAllowancesPerDiemLbl);
        end;
        exit(ExpensePerDiemRefundableLbl);
    end;

    local procedure ExpensePerDiemRefundableSearch(): Text[30]
    begin
        case GetCountryCode() of
            'CZ', 'NL', 'CH', 'IT':
                exit(ExpensePerDiemAllowanceSearchLbl);
            'BE', 'FI':
                exit(ExpensePerDiemAllowanceHyphenSearchLbl);
            'NO':
                exit(ExpenseSubsistenceSearchLbl);
            'DK':
                exit(ExpensePerDiemLowerSearchLbl);
        end;
        exit(ExpensePerDiemRefundableSearchLbl);
    end;

    local procedure ExpenseMileageRefundableAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'CZ', 'BE', 'CH', 'FI':
                exit(ExpenseMileageAllowanceLbl);
            'NL':
                exit(ExpenseMileageReimbursementLbl);
            'IT':
                exit(ExpenseGasolineMotorOilLbl);
            'NO':
                exit(ExpenseCarAllowanceLbl);
            'DK':
                exit(ExpenseMileageRateLbl);
        end;
        exit(ExpenseMileageRefundableLbl);
    end;

    local procedure ExpenseMileageRefundableSearch(): Text[30]
    begin
        case GetCountryCode() of
            'CZ', 'BE', 'CH', 'FI':
                exit(ExpenseMileageAllowanceSearchLbl);
            'NL':
                exit(ExpenseMileageReimbursementSearchLbl);
            'IT':
                exit(ExpenseGasolineMotorOilSearchLbl);
            'NO':
                exit(ExpenseCarAllowanceSearchLbl);
        end;
        exit(ExpenseMileageRefundableSearchLbl);
    end;

    local procedure ExpenseMealsRefundableAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'CZ', 'CH':
                exit(ExpenseMealsHospitalityLbl);
            'BE':
                exit(ExpenseBusinessMealsLbl);
            'FI':
                exit(ExpenseBusinessMealExpensesLbl);
            'NL':
                exit(ExpenseBoardAndLodgingLbl);
            'IT':
                exit(ExpenseEntertainmentAndPRLbl);
            'NO':
                exit(ExpenseEntertainmentDeductibleLbl);
            'DE':
                exit(ExpenseBoardAndLodgingLbl);
            'DK':
                exit(ExpenseRestaurantDiningLbl);
        end;
        exit(ExpenseMealsRefundableLbl);
    end;

    local procedure ExpenseMealsRefundableSearch(): Text[30]
    begin
        case GetCountryCode() of
            'CZ', 'CH':
                exit(ExpenseMealsHospitalitySearchLbl);
            'BE':
                exit(ExpenseBusinessMealsSearchLbl);
            'FI':
                exit(ExpenseBusinessMealExpensesSearchLbl);
            'NL':
                exit(ExpenseBoardAndLodgingSearchLbl);
            'IT':
                exit(ExpenseEntertainmentAndPRSearchLbl);
            'NO':
                exit(ExpenseEntertainmentDeductibleSearchLbl);
            'DK':
                exit(ExpenseRestaurantSearchLbl);
        end;
        exit(ExpenseMealsRefundableSearchLbl);
    end;

    local procedure ExpenseEntertainRefundableAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'NL':
                exit(ExpenseBusinessMealsEntertainLbl);
            'CH', 'FI':
                exit(ExpenseEntertainmentExpensesLbl);
            'BE', 'IT':
                exit(ExpenseEntertainmentAndPRLbl);
            'NO':
                exit(ExpenseEntertainmentDeductibleLbl);
            'CZ':
                exit(ExpenseRepresentationCostsLbl);
            'AU':
                exit(ExpenseEntertainmentAndPRLbl);
            'CA':
                exit(ExpenseEntertainmentAndPRLbl);
            'DK':
                exit(ExpenseEntWineTobaccoSpiritsLbl);
            'ES':
                exit(ExpenseEntertainmentExpensesLbl);
        end;
        exit(ExpenseEntertainRefundableLbl);
    end;

    local procedure ExpenseEntertainRefundableSearch(): Text[30]
    begin
        case GetCountryCode() of
            'NL':
                exit(ExpenseBusinessMealsEntertainSearchLbl);
            'CH', 'FI':
                exit(ExpenseEntertainmentExpensesSearchLbl);
            'BE', 'IT':
                exit(ExpenseEntertainmentAndPRSearchLbl);
            'NO':
                exit(ExpenseEntertainmentDeductibleSearchLbl);
            'CZ':
                exit(ExpenseRepresentationCostsSearchLbl);
        end;
        exit(ExpenseEntertainRefundableSearchLbl);
    end;

    local procedure ExpenseNonRefundableAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'BE', 'CZ', 'FI', 'NO':
                exit(ExpenseNonRefundableEmpLbl);
            'IT', 'NL':
                exit(ExpenseNonDeductibleEmpLbl);
            'CH':
                exit(ExpenseOtherPersonnelCostsLbl);
            'AU':
                exit(ExpenseFinanceChargesVendorsLbl);
            'CA':
                exit(ExpenseFinanceChargesVendorsLbl);
            'DE':
                exit(ExpenseTravelRefundableLbl);
            'DK':
                exit(ExpenseNonDeductibleTravelLbl);
            'ES':
                exit(ExpenseOtherNondeductTravelLbl);
        end;
        exit(ExpenseOtherNonRefundableLbl);
    end;

    local procedure ExpenseNonRefundableSearch(): Text[30]
    begin
        case GetCountryCode() of
            'GB', 'US':
                exit(ExpenseOtherNonRefundableSearchGBLbl);
            'BE', 'CZ', 'FI', 'NO':
                exit(ExpenseNonRefundableEmpSearchLbl);
            'IT', 'NL':
                exit(ExpenseNonDeductibleEmpSearchLbl);
            'CH':
                exit(ExpenseOtherPersonnelCostsSearchLbl);
            'AU':
                exit(ExpenseFinanceChargesVendorsSearchLbl);
            'CA':
                exit(ExpenseFinanceChargesVendorsSearchLbl);
            'DE':
                exit(ExpenseTravelSearchLbl);
            'DK':
                exit(ExpenseNonDeductibleTravelSearchLbl);
            'ES':
                exit(ExpenseOtherNondeductTravelSearchLbl);
        end;
        exit(ExpenseOtherNonRefundableSearchLbl);
    end;

    local procedure ExpensePrepaymentDebitAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'CZ', 'CH':
                exit(ExpenseEmpExpenseAdvancesLbl);
            'BE':
                exit(ExpenseEmpTravelAdvancesLbl);
            'IT':
                exit(ExpenseEmpAdvancesPrepaymentsLbl);
            'NO':
                exit(ExpenseEmpExpensePrepaymentsLbl);
            'NL':
                exit(ExpenseCurrentReceivableEmpLbl);
            'FI':
                exit(ExpenseOtherreceivables1Lbl);
            'AU':
                exit(ExpenseEmployeePrepaymentsExpLbl);
            'CA':
                exit(ExpenseEmployeePrepaymentsExpLbl);
            'DE':
                exit(ExpenseAssetsPrepaidLbl);
            'DK':
                exit(ExpensePrepaymentsAccruedCostsLbl);
            'ES':
                exit(ExpenseExpensesPrepaymentsLbl);
        end;
        exit(ExpenseOtherPrepaymentLbl);
    end;

    local procedure ExpensePrepaymentDebitSearch(): Text[30]
    begin
        case GetCountryCode() of
            'GB':
                exit(ExpenseOtherPrepaymentSearchGBLbl);
            'CZ', 'CH':
                exit(ExpenseEmpExpenseAdvancesSearchLbl);
            'BE':
                exit(ExpenseEmpTravelAdvancesSearchLbl);
            'IT':
                exit(ExpenseEmpAdvancesPrepaymentsSearchLbl);
            'NO':
                exit(ExpenseEmpExpensePrepaymentsSearchLbl);
            'NL':
                exit(ExpenseCurrentReceivableEmpSearchLbl);
            'FI':
                exit(ExpenseOtherreceivables1SearchLbl);
            'AU':
                exit(ExpenseEmployeePrepaymentsExpSearchLbl);
            'CA':
                exit(ExpenseEmployeePrepaymentsExpSearchLbl);
            'DK':
                exit(ExpensePrepaymentsAccruedSearchLbl);
            'ES':
                exit(ExpenseExpensesPrepaymentsSearchLbl);
        end;
        exit(ExpenseOtherPrepaymentSearchLbl);
    end;

    local procedure ExpenseDebitRoundingAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'AT':
                exit(ExpenseApplicationRoundingLbl);
            'BE', 'CZ', 'FI', 'NO':
                exit(ExpenseRoundingDifferencesLbl);
            'IT':
                exit(ExpenseInvoiceRoundingLbl);
            'CH':
                exit(ExpenseRoundingDiffPurchaseLbl);
            'AU':
                exit(ExpenseInvoiceRoundingLbl);
            'CA':
                exit(ExpenseInvoiceRoundingLbl);
            'DE':
                exit(ExpenseSalesInvoiceRoundingLbl);
            'DK':
                exit(ExpenseCentDiscrepanciesLbl);
            'ES':
                exit(ExpenseRoundingExpensesOperatingLbl);
        end;
        exit(ExpenseOtherDebitRoundingLbl);
    end;

    local procedure ExpenseCreditRoundingAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'AT':
                exit(ExpenseApplicationRoundingLbl);
            'BE', 'CZ', 'FI', 'NO':
                exit(ExpenseRoundingDifferencesLbl);
            'IT':
                exit(ExpenseInvoiceRoundingLbl);
            'CH':
                exit(ExpenseRoundingDiffPurchaseLbl);
            'AU':
                exit(ExpenseInvoiceRoundingLbl);
            'CA':
                exit(ExpenseInvoiceRoundingLbl);
            'DE':
                exit(ExpenseSalesInvoiceRoundingLbl);
            'DK':
                exit(ExpenseCentDiscrepanciesLbl);
            'ES':
                exit(ExpenseRoundingExpensesOperatingLbl);
        end;
        exit(ExpenseOtherCreditRoundingLbl);
    end;

    local procedure ExpenseRoundingSearch(): Text[30]
    begin
        case GetCountryCode() of
            'BE', 'CZ', 'FI', 'NO':
                exit(ExpenseRoundingDifferencesSearchLbl);
            'IT':
                exit(ExpenseInvoiceRoundingSearchLbl);
            'CH':
                exit(ExpenseRoundingDiffPurchaseSearchLbl);
        end;
        exit(ExpenseRoundingSearchLbl);
    end;

    local procedure ExpenseReportPayableAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'CH':
                exit(ExpenseEmpExpReimbursementsPayableLbl);
            'IT':
                exit(ExpenseEmpExpReimbursementPayableLbl);
            'NO':
                exit(ExpenseEmpExpPayableCashLbl);
            'CZ':
                exit(ExpensePayablesToEmployeesLbl);
            'NL':
                exit(ExpenseCurrentLiabilitiesEmpLbl);
            'US':
                exit(ExpenseAccountsPayableDomesticLbl);
            'CA':
                exit(ExpenseVacationCompPayableLbl);
            'DK':
                exit(ExpenseAccountsPayablesLbl);
            'ES':
                exit(ExpenseRemunerationAdvancesLbl);
        end;
        exit(ExpensePayableCashLbl);
    end;

    local procedure ExpensePayableBankPaidAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'BE':
                exit(ExpenseCompanyPaidExpClearingLbl);
            'CH', 'FI', 'IT':
                exit(ExpenseCompanyPaidExpClearHyphenLbl);
            'NL':
                exit(ExpenseBankPaidExpClearingLbl);
            'NO':
                exit(ExpenseEmpExpPayableCompPaidLbl);
            'CZ':
                exit(ExpenseBankAccountKBLbl);
            'AU', 'AT', 'FR':
                exit(ExpenseBankLCYLbl);
            'CA':
                exit(ExpenseBankCheckingLbl);
            'DE':
                exit(ExpenseBusinessAccountOperatingLbl);
            'DK':
                exit(ExpenseBankLbl);
            'ES':
                exit(ExpenseBanksEuroLbl);
        end;
        exit(ExpensePayableBankPaidLbl);
    end;

    local procedure ExpensePayableBankPaidSearch(): Text[30]
    begin
        case GetCountryCode() of
            'BE':
                exit(ExpenseCompanyPaidExpClearingSearchLbl);
            'CH', 'FI', 'IT':
                exit(ExpenseCompanyPaidExpClearHyphenSearchLbl);
            'NL':
                exit(ExpenseBankPaidExpClearingSearchLbl);
            'NO':
                exit(ExpenseEmpExpPayableCompPaidSearchLbl);
            'CZ':
                exit(ExpenseBankAccountKBSearchLbl);
        end;
        exit(ExpensePayableBankPaidSearchLbl);
    end;

    local procedure ExpensePayableCardPaidAccountName(): Text[100]
    begin
        case GetCountryCode() of
            'BE', 'IT':
                exit(ExpenseCorporateCardExpClearingLbl);
            'CH', 'CZ':
                exit(ExpenseCompanyCardExpPayableLbl);
            'FI':
                exit(ExpenseCompanyCardExpClearingLbl);
            'NL':
                exit(ExpenseCorporateCardExpPayableLbl);
            'NO':
                exit(ExpenseEmpExpPayableCompCardLbl);
            'DE', 'AT':
                exit(ExpenseCompanyCreditCardClearingLbl);
            'DK':
                exit(ExpenseCompanyCreditCardsLbl);
            'ES':
                exit(ExpenseCompanyCreditCardClearingLbl);
        end;
        exit(ExpensePayableCardPaidLbl);
    end;

    local procedure ExpensePayableCardPaidSearch(): Text[30]
    begin
        case GetCountryCode() of
            'AT':
                exit(ExpenseCreditCardClearingSearchLbl);
            'BE', 'IT':
                exit(ExpenseCorporateCardExpClearingSearchLbl);
            'CH', 'CZ':
                exit(ExpenseCompanyCardExpPayableSearchLbl);
            'FI':
                exit(ExpenseCompanyCardExpClearingSearchLbl);
            'NL':
                exit(ExpenseCorporateCardExpPayableSearchLbl);
            'NO':
                exit(ExpenseEmpExpPayableCompCardSearchLbl);
        end;
        exit(ExpensePayableCardPaidSearchLbl);
    end;

    internal procedure ExpensePayableBankPaidAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePayableBankPaidAccountName(), ExpensePayableBankPaidSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'CZ':
                exit('221100');
            'US':
                exit('18400');
            'AU':
                exit('1010');
            'CA':
                exit('11120');
            'DE':
                exit('1810');
            'DK':
                exit('18200');
            'ES':
                exit('5720001');
            'FR':
                exit('512100');
            'NZ':
                exit('2920');
            'AT':
                exit('2800');
            'BE':
                exit('457100');
            'CH':
                exit('2272');
            'FI':
                exit('2917');
            'IT':
                exit('5853');
            'NL':
                exit('1522');
            'NO':
                exit('5962');
        end;
        exit('78400');
    end;

    internal procedure ExpensePayableCardPaidAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePayableCardPaidAccountName(), ExpensePayableCardPaidSearch());
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'GB':
                exit('78410');
            'US':
                exit('18600');
            'AU':
                exit('1025');
            'CA':
                exit('11160');
            'DE':
                exit('3510');
            'DK':
                exit('18300');
            'ES':
                exit('5721001');
            'FR':
                exit('512900');
            'NZ':
                exit('2950');
            'AT':
                exit('2830');
            'BE':
                exit('457200');
            'CH':
                exit('2271');
            'CZ':
                exit('325200');
            'FI':
                exit('2916');
            'IT':
                exit('5852');
            'NL':
                exit('1521');
            'NO':
                exit('5961');
        end;
        exit('78600');
    end;

    internal procedure ExpenseProfitLossAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Assets, ExpenseProfitLossLbl, ExpenseProfitLossSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('1290001');
    end;

    internal procedure ExpensePrepaymentBeginAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePrepaymentBeginLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'CA':
                exit('13600');
            'NZ':
                exit('2500');
        end;
    end;

    internal procedure ExpensePrepaymentTotalAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePrepaymentTotalLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        case GetCountryCode() of
            'CA':
                exit('13690');
            'NZ':
                exit('2590');
        end;
    end;

    internal procedure FindExistingExpenseAccount(AccountCategory: Enum "G/L Account Category"; FullDescription: Text; PartialDescription: Text) AccNo: Code[20]
    begin
        AccNo := FindExistingExpenseAccount(AccountCategory, FullDescription);
        if AccNo <> '' then
            exit;
        AccNo := FindExistingExpenseAccount(AccountCategory, PartialDescription);
    end;

    internal procedure FindExistingExpenseAccount(AccountCategory: Enum "G/L Account Category"; SearchDescription: Text): Code[20]
    var
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
    begin
        if SearchDescription = '' then
            exit('');
        SearchDescription := ConvertStr(SearchDescription, ' ', '*');
        SearchDescription := '@*' + SearchDescription + '*'; // ignore case, any position in text

        GLAccount.SetRange("Account Category", AccountCategory);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);

        GLAccount.SetFilter(Name, SearchDescription);
        if GLAccount.FindFirst() then
            exit(GLAccount."No.");

        GLAccount.SetRange(Name);
        GLAccountCategory.SetRange("Account Category", AccountCategory);
        GLAccountCategory.SetFilter(Description, SearchDescription);
        if GLAccountCategory.FindSet() then
            repeat
                GLAccount.SetRange("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
                if GLAccount.FindFirst() then
                    exit(GLAccount."No.");
            until GLAccountCategory.Next() = 0;

        exit('');
    end;

    local procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.SetLoadFields("Country/Region Code");
        if CompanyInformation.Get() then
            exit(CompanyInformation."Country/Region Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLAccount(var IsHandled: Boolean)
    begin
    end;
}