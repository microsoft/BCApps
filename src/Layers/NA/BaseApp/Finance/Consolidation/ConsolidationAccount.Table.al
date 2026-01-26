// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using System.Environment;

/// <summary>
/// Stores consolidation account master data for mapping subsidiary G/L accounts to consolidated accounts.
/// Used during consolidation processing to standardize account structures across business units.
/// </summary>
/// <remarks>
/// Consolidation accounts define the chart of accounts structure for consolidated financial reporting.
/// Maps subsidiary company accounts to standardized consolidation account numbers and categories.
/// </remarks>
table 1829 "Consolidation Account"
{
    Caption = 'Consolidation Account';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique consolidation account number used for mapping subsidiary accounts during consolidation.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name of the consolidation account for identification and reporting purposes.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Classification of account as Income Statement or Balance Sheet account for consolidation reporting.
        /// </summary>
        field(3; "Income/Balance"; Enum "G/L Account Report Type")
        {
            Caption = 'Income/Balance';
        }
        /// <summary>
        /// Indicates if consolidation account is blocked from use in consolidation processing.
        /// </summary>
        field(4; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Specifies whether direct posting to this consolidation account is allowed during consolidation.
        /// </summary>
        field(5; "Direct Posting"; Boolean)
        {
            Caption = 'Direct Posting';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        XTaxesTok: Label 'Taxes';
        XOtherMarketableSecuritiesTok: Label 'Other Marketable Securities';
        XAccruedSalariesWagesTok: Label 'Accrued Salaries & Wages';
        XHealthInsuranceTok: Label 'Health Insurance';
        XGroupLifeInsuranceTok: Label 'Group Life Insurance';
        XWorkersCompensationTok: Label 'Workers Compensation';
        XStateIncomeTaxTok: Label 'State Income Tax';
        XIncreasesduringtheYearTok: Label 'Increases during the Year';
        XDecreasesduringtheYearTok: Label 'Decreases during the Year';
        XAccumDepreciationBuildingsTok: Label 'Accum. Depreciation, Buildings';
        XOperatingEquipmentTok: Label 'Operating Equipment';
        XAccumDeprOperEquipTok: Label 'Accum. Depr., Oper. Equip.';
        XVehiclesTok: Label 'Vehicles';
        XAccumDepreciationVehiclesTok: Label 'Accum. Depreciation, Vehicles';
        XResaleItemsTok: Label 'Resale Items';
        XResaleItemsInterimTok: Label 'Resale Items (Interim)';
        XCostofResaleSoldInterimTok: Label 'Cost of Resale Sold (Interim)';
        XFinishedGoodsTok: Label 'Finished Goods';
        XRawMaterialsTok: Label 'Raw Materials';
        XCostofRawMatSoldInterimTok: Label 'Cost of Raw Mat.Sold (Interim)';
        XCustomersDomesticTok: Label 'Customers Domestic';
        XCustomersForeignTok: Label 'Customers, Foreign';
        XAccruedInterestTok: Label 'Accrued Interest';
        XOtherReceivablesTok: Label 'Other Receivables';
        XBondsTok: Label 'Bonds';
        XCashTok: Label 'Cash';
        XBankLCYTok: Label 'Bank, Checking';
        XBankCurrenciesTok: Label 'Bank Currencies';
        XGiroAccountTok: Label 'Bank Operations Cash';
        XCapitalStockTok: Label 'Capital Stock';
        XRetainedEarningsTok: Label 'Retained Earnings';
        XDeferredTaxesTok: Label 'Deferred Taxes';
        XLongtermBankLoansTok: Label 'Long-term Bank Loans';
        XMortgageTok: Label 'Mortgage';
        XRevolvingCreditTok: Label 'Revolving Credit';
        XVendorsDomesticTok: Label 'Vendors, Domestic';
        XVendorsForeignTok: Label 'Vendors, Foreign';
        XInvAdjmtInterimRetailTok: Label 'Inv. Adjmt. (Interim), Retail';
        XInvAdjmtInterimRawMatTok: Label 'Inv. Adjmt. (Interim), Raw Mat';
        XPurchaseTaxTokTok: Label 'Purchase Tax';
        XWithholdingTaxesPayableTok: Label 'Federal Withholding Payable';
        XSupplementaryTaxesPayableTok: Label 'State Withholding Payable';
        XPayrollTaxesPayableTok: Label 'Payroll Taxes Payable';
        XCorporateTaxesPayableTok: Label 'Corporate Taxes Payable';
        XSalesRetailDomTok: Label 'Sales, Retail - Dom.';
        XSalesRetailExportTok: Label 'Sales, Retail - Export';
        XSalesRawMaterialsDomTok: Label 'Sales, Raw Materials - Dom.';
        XSalesRawMaterialsExportTok: Label 'Sales, Raw Materials - Export';
        XJobSalesAdjmtRawMatTok: Label 'Job Sales Adjmt., Raw Mat.';
        XSalesResourcesDomTok: Label 'Sales, Resources - Dom.';
        XSalesResourcesExportTok: Label 'Sales, Resources - Export';
        XConsultingFeesDomTok: Label 'Consulting Fees - Dom.';
        XFeesandChargesRecDomTok: Label 'Fees and Charges Rec. - Dom.';
        XFeesandChargesRecEUTxtTok: Label 'Fees and Charges Rec. - EU';
        XDiscountGrantedTok: Label 'Discount Granted';
        XPurchRetailDomTok: Label 'Purch., Retail - Dom.';
        XPurchRetailExportTok: Label 'Purch., Retail - Export';
        XDiscReceivedRetailTok: Label 'Disc. Received, Retail';
        XDeliveryExpensesRetailTok: Label 'Delivery Expenses, Retail';
        XInventoryAdjmtRetailTok: Label 'Inventory Adjmt., Retail';
        XCostofRetailSoldTok: Label 'Cost of Retail Sold';
        XPurchRawMaterialsDomTok: Label 'Purch., Raw Materials - Dom.';
        XPurchRawMaterialsExportTok: Label 'Purch., Raw Materials - Export';
        XInventoryAdjmtRawMatTok: Label 'Inventory Adjmt., Raw Mat.';
        XCostofRawMaterialsSoldTok: Label 'Cost of Raw Materials Sold';
        XCostofResourcesUsedTok: Label 'Cost of Resources Used';
        XJobCostsTok: Label 'Job Costs';
        XCleaningTok: Label 'Cleaning';
        XElectricityandHeatingTok: Label 'Electricity and Heating';
        XRepairsandMaintenanceTok: Label 'Repairs and Maintenance';
        XOfficeSuppliesTok: Label 'Office Supplies';
        XPhoneandFaxTok: Label 'Phone and Fax';
        XPostageTok: Label 'Postage';
        XSoftwareTok: Label 'Software';
        XConsultantServicesTok: Label 'Consultant Services';
        XOtherComputerExpensesTok: Label 'Other Computer Expenses';
        XAdvertisingTok: Label 'Advertising';
        XEntertainmentandPRTok: Label 'Entertainment and PR';
        XTravelTok: Label 'Travel';
        XDeliveryExpensesTok: Label 'Delivery Expenses';
        XGasolineandMotorOilTok: Label 'Gasoline and Motor Oil';
        XRegistrationFeesTok: Label 'Registration Fees';
        XCashDiscrepanciesTok: Label 'Cash Discrepancies';
        XBadDebtExpensesTok: Label 'Bad Debt Expenses';
        XLegalandAccountingServicesTok: Label 'Legal and Accounting Services';
        XMiscellaneousTok: Label 'Miscellaneous';
        XWagesTok: Label 'Wages';
        XSalariesTok: Label 'Salaries';
        XRetirementPlanContributionsTok: Label 'Retirement Plan Contributions';
        XVacationCompensationTok: Label 'Vacation Compensation';
        XPayrollTaxesTok: Label 'Payroll Taxes';
        XDepreciationBuildingsTok: Label 'Depreciation, Buildings';
        XDepreciationEquipmentTok: Label 'Depreciation, Equipment';
        XDepreciationVehiclesTok: Label 'Depreciation, Vehicles';
        XGainsandLossesTok: Label 'Gains and Losses';
        XOtherCostsofOperationsTok: Label 'Other Costs of Operations';
        XInterestonBankBalancesTok: Label 'Interest on Bank Balances';
        XFinanceChargesfromCustomersTok: Label 'Finance Charges from Customers';
        XPaymentDiscountsReceivedTok: Label 'Payment Discounts Received';
        XPmtDiscReceivedDecreasesTok: Label 'PmtDisc. Received - Decreases';
        XPaymentToleranceReceivedTok: Label 'Payment Tolerance Received';
        XPmtTolReceivedDecreasesTok: Label 'Pmt. Tol. Received Decreases';
        XInvoiceRoundingTok: Label 'Invoice Rounding';
        XApplicationRoundingTok: Label 'Application Rounding';
        XInterestonRevolvingCreditTok: Label 'Interest on Revolving Credit';
        XInterestonBankLoansTok: Label 'Interest on Bank Loans';
        XMortgageInterestTok: Label 'Mortgage Interest';
        XFinanceChargestoVendorsTok: Label 'Finance Charges to Vendors';
        XPaymentDiscountsGrantedTok: Label 'Payment Discounts Granted';
        XPmtDiscGrantedDecreasesTok: Label 'PmtDisc. Granted - Decreases';
        XPaymentToleranceGrantedTok: Label 'Payment Tolerance Granted';
        XPmtTolGrantedDecreasesTok: Label 'Pmt. Tol. Granted Decreases';
        XUnrealizedFXGainsTok: Label 'Unrealized FX Gains';
        XUnrealizedFXLossesTok: Label 'Unrealized FX Losses';
        XRealizedFXGainsTok: Label 'Realized FX Gains';
        XRealizedFXLossesTok: Label 'Realized FX Losses';
        XExtraordinaryIncomeTok: Label 'Extraordinary Income';
        XExtraordinaryExpensesTok: Label 'Extraordinary Expenses';
        XCorporateTaxTok: Label 'Corporate Tax';
        XVendorPrepaymentsVATTok: Label 'Vendor Prepayments %1', Comment = '%1=No Vat, Services, or Retail.  Do not translate.';
        XCustomerPrepaymentsVATTok: Label 'Customer Prepayments %1', Comment = '%1=No Vat, Services, or Retail.  Do not translate.';
        XGSTHSTTok: Label 'GST/HST - Sales Tax';
        XPSTTok: Label 'Provincial Sales Tax';
        XACCRUEDPAYABLESTok: Label 'Accrued Payables';
        XLandTok: Label 'Land';
        XBuildingsTok: Label 'Buildings';
        XRentExpensesTok: Label 'Rent expenses';
        XNOVATTok: Label 'NO VAT', Comment = 'Do not translate.';
        XRETAILTok: Label 'RETAIL', Comment = 'Do not translate.';
        XSERVICESTok: Label 'SERVICES', Comment = 'Do not translate.';

    [Scope('OnPrem')]
    procedure PopulateAccountsForCA()
    begin
        InsertData('18400', XLandTok, 1, false);
        InsertData('18100', XBuildingsTok, 1, false);
        InsertData('18110', XIncreasesduringtheYearTok, 1, false);
        InsertData('18120', XDecreasesduringtheYearTok, 1, false);
        InsertData('18200', XAccumDepreciationBuildingsTok, 1, false);
        InsertData('17100', XOperatingEquipmentTok, 1, true);
        InsertData('17110', XIncreasesduringtheYearTok, 1, true);
        InsertData('17120', XDecreasesduringtheYearTok, 1, false);
        InsertData('17200', XAccumDeprOperEquipTok, 1, true);
        InsertData('16200', XVehiclesTok, 1, false);
        InsertData('16210', XIncreasesduringtheYearTok, 1, true);
        InsertData('16220', XDecreasesduringtheYearTok, 1, false);
        InsertData('16300', XAccumDepreciationVehiclesTok, 1, false);
        InsertData('14302', XCostofRawMatSoldInterimTok, 1, false);
        InsertData('53400', XInventoryAdjmtRawMatTok, 0, true);
        InsertData('14100', XResaleItemsTok, 1, true);
        InsertData('14101', XResaleItemsInterimTok, 1, false);
        InsertData('14102', XCostofResaleSoldInterimTok, 1, false);
        InsertData('14200', XFinishedGoodsTok, 1, false);
        InsertData('14300', XRawMaterialsTok, 1, false);
        InsertData('13100', XCustomersDomesticTok, 1, true);
        InsertData('13200', XCustomersForeignTok, 1, false);
        InsertData('13300', XAccruedInterestTok, 1, true);
        InsertData('13350', XOtherReceivablesTok, 1, true);
        InsertData('13510', StrSubstNo(XVendorPrepaymentsVATTok, XNOVATTok), 1, false);
        InsertData('13520', StrSubstNo(XVendorPrepaymentsVATTok, XSERVICESTok), 1, false);
        InsertData('13530', StrSubstNo(XVendorPrepaymentsVATTok, XRETAILTok), 1, false);
        InsertData('12100', XBondsTok, 1, true);
        InsertData('11200', XCashTok, 1, true);
        InsertData('11400', XBankLCYTok, 1, true);
        InsertData('11500', XBankCurrenciesTok, 1, false);
        InsertData('11600', XGiroAccountTok, 1, false);
        InsertData('12200', XOtherMarketableSecuritiesTok, 1, true);
        InsertData('30100', XCapitalStockTok, 1, true);
        InsertData('30200', XRetainedEarningsTok, 1, true);
        InsertData('25300', XDeferredTaxesTok, 1, false);
        InsertData('25100', XLongtermBankLoansTok, 1, true);
        InsertData('25200', XMortgageTok, 1, true);
        InsertData('22100', XRevolvingCreditTok, 1, false);
        InsertData('22160', StrSubstNo(XCustomerPrepaymentsVATTok, XNOVATTok), 1, false);
        InsertData('22170', StrSubstNo(XCustomerPrepaymentsVATTok, XSERVICESTok), 1, false);
        InsertData('22180', StrSubstNo(XCustomerPrepaymentsVATTok, XRETAILTok), 1, false);
        InsertData('22300', XVendorsDomesticTok, 1, true);
        InsertData('22400', XVendorsForeignTok, 1, false);
        InsertData('22450', XACCRUEDPAYABLESTok, 1, false);
        InsertData('22700', XPSTTok, 1, true);
        InsertData('22750', XPurchaseTaxTokTok, 1, false);
        InsertData('22780', XGSTHSTTok, 1, true);
        InsertData('22530', XInvAdjmtInterimRawMatTok, 1, false);
        InsertData('22550', XInvAdjmtInterimRetailTok, 1, false);
        InsertData('23050', XAccruedSalariesWagesTok, 1, true);
        InsertData('23100', XWithholdingTaxesPayableTok, 1, true);
        InsertData('23200', XSupplementaryTaxesPayableTok, 1, true);
        InsertData('23300', XPayrollTaxesPayableTok, 1, true);
        InsertData('24300', XCorporateTaxesPayableTok, 1, true);

        InsertData('44100', XSalesRetailDomTok, 0, false);
        InsertData('44300', XSalesRetailExportTok, 0, false);
        InsertData('42100', XSalesResourcesDomTok, 0, false);
        InsertData('42300', XSalesResourcesExportTok, 0, false);
        InsertData('43100', XSalesRawMaterialsDomTok, 0, true);
        InsertData('43300', XSalesRawMaterialsExportTok, 0, true);
        InsertData('43400', XJobSalesAdjmtRawMatTok, 0, true);
        InsertData('45000', XConsultingFeesDomTok, 0, true);
        InsertData('45100', XFeesandChargesRecDomTok, 0, true);
        InsertData('996820', XFeesandChargesRecEUTxtTok, 0, true);
        InsertData('45200', XDiscountGrantedTok, 0, false);
        InsertData('47100', XInterestonBankBalancesTok, 0, true);
        InsertData('47200', XFinanceChargesfromCustomersTok, 0, true);
        InsertData('47300', XPaymentDiscountsReceivedTok, 0, false);
        InsertData('47260', XPmtDiscReceivedDecreasesTok, 0, false);
        InsertData('47400', XInvoiceRoundingTok, 0, false);
        InsertData('47500', XApplicationRoundingTok, 0, false);
        InsertData('47510', XPaymentToleranceReceivedTok, 0, false);
        InsertData('47520', XPmtTolReceivedDecreasesTok, 0, false);
        InsertData('48100', XUnrealizedFXGainsTok, 0, false);
        InsertData('48200', XUnrealizedFXLossesTok, 0, false);
        InsertData('48300', XRealizedFXGainsTok, 0, false);
        InsertData('48400', XRealizedFXLossesTok, 0, false);
        InsertData('51000', XJobCostsTok, 0, true);
        InsertData('52200', XCostofResourcesUsedTok, 0, true);

        InsertData('53100', XPurchRawMaterialsDomTok, 0, true);
        InsertData('53200', XPurchRawMaterialsExportTok, 0, true);
        InsertData('53600', XCostofRawMaterialsSoldTok, 0, true);

        InsertData('54400', XDiscReceivedRetailTok, 0, true);
        InsertData('54100', XPurchRetailDomTok, 0, false);
        InsertData('54300', XPurchRetailExportTok, 0, false);
        InsertData('997150', XDeliveryExpensesRetailTok, 0, true);
        InsertData('54500', XInventoryAdjmtRetailTok, 0, false);
        InsertData('54700', XCostofRetailSoldTok, 0, false);
        InsertData('65100', XCleaningTok, 0, true);
        InsertData('65200', XElectricityandHeatingTok, 0, true);
        InsertData('65300', XRepairsandMaintenanceTok, 0, true);
        InsertData('65600', XOfficeSuppliesTok, 0, true);
        InsertData('65700', XPhoneandFaxTok, 0, true);
        InsertData('65800', XPostageTok, 0, true);
        InsertData('64100', XSoftwareTok, 0, true);
        InsertData('64200', XConsultantServicesTok, 0, true);
        InsertData('64300', XOtherComputerExpensesTok, 0, true);
        InsertData('64450', XRentExpensesTok, 0, true);
        InsertData('61100', XAdvertisingTok, 0, true);
        InsertData('61200', XEntertainmentandPRTok, 0, true);
        InsertData('61300', XTravelTok, 0, true);
        InsertData('61350', XDeliveryExpensesTok, 0, true);
        InsertData('63100', XGasolineandMotorOilTok, 0, true);
        InsertData('63200', XRegistrationFeesTok, 0, true);
        InsertData('63300', XRepairsandMaintenanceTok, 0, true);
        InsertData('63450', XTaxesTok, 0, true);
        InsertData('67100', XCashDiscrepanciesTok, 0, true);
        InsertData('67200', XBadDebtExpensesTok, 0, true);
        InsertData('67300', XLegalandAccountingServicesTok, 0, true);
        InsertData('67400', XMiscellaneousTok, 0, true);
        InsertData('62100', XWagesTok, 0, true);
        InsertData('62200', XSalariesTok, 0, true);
        InsertData('62300', XRetirementPlanContributionsTok, 0, true);
        InsertData('62400', XVacationCompensationTok, 0, true);
        InsertData('62500', XPayrollTaxesTok, 0, true);
        InsertData('62600', XHealthInsuranceTok, 0, true);

        InsertData('62700', XGroupLifeInsuranceTok, 0, true);
        InsertData('62800', XWorkersCompensationTok, 0, true);

        InsertData('66100', XDepreciationBuildingsTok, 0, true);
        InsertData('66200', XDepreciationEquipmentTok, 0, true);
        InsertData('66300', XDepreciationVehiclesTok, 0, true);
        InsertData('48500', XGainsandLossesTok, 0, false);
        InsertData('67500', XOtherCostsofOperationsTok, 0, true);

        InsertData('68100', XInterestonRevolvingCreditTok, 0, true);
        InsertData('68200', XInterestonBankLoansTok, 0, true);
        InsertData('68300', XMortgageInterestTok, 0, true);
        InsertData('68400', XFinanceChargestoVendorsTok, 0, true);
        InsertData('54800', XPaymentDiscountsGrantedTok, 0, false);
        InsertData('68455', XPmtDiscGrantedDecreasesTok, 0, false);
        InsertData('68460', XPaymentToleranceGrantedTok, 0, false);
        InsertData('68470', XPmtTolGrantedDecreasesTok, 0, false);
        InsertData('85100', XExtraordinaryIncomeTok, 0, true);
        InsertData('85200', XExtraordinaryExpensesTok, 0, true);
        InsertData('84100', XCorporateTaxTok, 0, true);
        InsertData('84200', XStateIncomeTaxTok, 0, true);
    end;

    [Scope('OnPrem')]
    procedure PopulateAccountsForUS()
    begin
        InsertData('10100', 'Checking account', 1, true);
        InsertData('10200', 'Savings account', 1, true);
        InsertData('10300', 'Petty Cash', 1, true);
        InsertData('10400', 'Accounts Receivable', 1, true);
        InsertData('10500', 'Prepaid Rent', 1, true);
        InsertData('10600', 'Prepaid Insurance', 1, true);
        InsertData('10700', 'Inventory', 1, true);
        InsertData('10800', 'Equipment', 1, true);
        InsertData('10900', 'Accumulated Depreciation', 1, true);
        InsertData('20100', 'Accounts Payable', 0, true);
        InsertData('20200', 'Purchase Discounts', 0, false);
        InsertData('20300', 'Purchase Returns & Allowances', 0, false);
        InsertData('20400', 'Deferred Revenue', 0, false);
        InsertData('20500', 'Credit Cards', 0, false);
        InsertData('20600', 'Sales Tax Payable', 0, false);
        InsertData('20700', 'Accrued Salaries & Wages', 0, true);
        InsertData('20800', 'Federal Withholding Payable', 0, true);
        InsertData('20900', 'State Withholding Payable', 0, true);
        InsertData('21000', 'FICA Payable', 0, true);
        InsertData('21100', 'Medicare Payable', 0, true);
        InsertData('21200', 'FUTA Payable', 0, true);
        InsertData('21300', 'SUTA Payable', 0, true);
        InsertData('21400', 'Employee Benefits Payable', 0, true);
        InsertData('21500', 'Vacation Compensation Payable', 0, true);
        InsertData('21600', 'Garnishment Payable', 0, true);
        InsertData('21700', 'Federal Income Taxes Payable', 0, true);
        InsertData('21800', 'State Income Tax Payable', 0, true);
        InsertData('21900', 'Notes Payable', 0, true);
        InsertData('30100', 'Capital Stock', 0, true);
        InsertData('30200', 'Retained Earnings', 0, true);
        InsertData('30300', 'Distributions to Shareholders', 0, true);
        InsertData('40000', 'INCOME STATEMENT', 0, true);
        InsertData('40001', 'INCOME', 0, true);
        InsertData('40100', 'Income, Services', 0, true);
        InsertData('40200', 'Income, Product Sales', 0, false);
        InsertData('40300', 'Sales Discounts', 0, false);
        InsertData('40400', 'Sales Returns & Allowances', 0, false);
        InsertData('40500', 'Interest Income', 0, true);
        InsertData('40990', 'TOTAL INCOME', 0, true);
        InsertData('50100', 'Cost of Materials', 1, false);
        InsertData('50200', 'Cost of Labor', 1, false);
        InsertData('60001', 'EXPENSES', 1, true);
        InsertData('60100', 'Rent Expense', 1, true);
        InsertData('60200', 'Advertising Expense', 1, true);
        InsertData('60300', 'Interest Expense', 1, true);
        InsertData('60400', 'Bank Charges and Fees', 1, true);
        InsertData('60500', 'Processing Fees', 1, true);
        InsertData('60600', 'Bad Debt Expense', 1, true);
        InsertData('60700', 'Salaries Expense', 1, true);
        InsertData('60800', 'Payroll Tax Expense', 1, true);
        InsertData('60900', 'Workers Compensation ', 1, true);
        InsertData('61000', 'Health & Dental Insurance Expense', 1, true);
        InsertData('61100', 'Life Insurance Expense', 1, true);
        InsertData('61200', 'Repairs and Maintenance Expense', 1, true);
        InsertData('61300', 'Utilities Expense', 1, true);
        InsertData('61400', 'Office Supplies Expense', 1, true);
        InsertData('61500', 'Miscellaneous Expense', 1, true);
        InsertData('61600', 'Depreciation, Equipment', 1, false);
        InsertData('61700', 'Federal Income Tax Expense', 1, true);
        InsertData('61800', 'State Income Tax Expense', 1, true);
        InsertData('61900', 'Rounding', 1, true);
        InsertData('61990', 'TOTAL EXPENSES', 1, true);
    end;

    /// <summary>
    /// Creates sample consolidation accounts with default configuration for initial setup.
    /// Inserts standard checking account entry as consolidation account template.
    /// </summary>
    procedure PopulateAccounts()
    begin
        InsertData('10100', 'Checking account', 1, true);
    end;

    local procedure InsertData(AccountNo: Code[20]; AccountName: Text[100]; IncomeBalance: Integer; DirectPosting: Boolean)
    var
        ConsolidationAccount: Record "Consolidation Account";
    begin
        ConsolidationAccount.Init();
        ConsolidationAccount.Validate("No.", AccountNo);
        ConsolidationAccount.Validate(Name, AccountName);
        ConsolidationAccount.Validate("Direct Posting", DirectPosting);
        ConsolidationAccount.Validate("Income/Balance", "G/L Account Report Type".FromInteger(IncomeBalance));
        ConsolidationAccount.Insert();
    end;

    /// <summary>
    /// Populates consolidation accounts by copying G/L account structure from an existing consolidated company.
    /// Creates consolidation account mapping based on existing G/L chart of accounts.
    /// </summary>
    /// <param name="ConsolidatedCompany">Name of the consolidated company to copy account structure from</param>
    procedure PopulateConsolidationAccountsForExistingCompany(ConsolidatedCompany: Text[50])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.ChangeCompany(ConsolidatedCompany);
        GLAccount.Reset();
        GLAccount.SetFilter("Account Type", Format(GLAccount."Account Type"::Posting));
        if GLAccount.Find('-') then
            repeat
                InsertData(GLAccount."No.", GLAccount.Name, GLAccount."Income/Balance".AsInteger(), GLAccount."Direct Posting");
            until GLAccount.Next() = 0;
    end;

    /// <summary>
    /// Validates if the provided country code matches the application system country configuration.
    /// Checks country code against the application version string for country-specific features.
    /// </summary>
    /// <param name="CountryCode">Two-character country code to validate</param>
    /// <returns>True if country code matches system configuration, false otherwise</returns>
    procedure ValidateCountry(CountryCode: Code[2]): Boolean
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        if StrPos(ApplicationSystemConstants.ApplicationVersion(), CountryCode) = 1 then
            exit(true);

        exit(false);
    end;
}

