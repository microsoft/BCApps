codeunit 101093 "Create Vendor Posting Group"
{

    // RU specific

    trigger OnRun()
    begin
        InsertData('55-3010', XDepositsLessThenYear,
          '55-3010', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('55-3020', XDepositsMoreThenYear,
          '55-3020', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('58-1120', XSharesOfSubAndChildCompanies,
          '58-1120', '', '', '', '91-1330', '', '', '', '', '', '', '');
        InsertData('58-3100', XShortTermLoansGranted,
          '58-3100', '', '', '', '91-1330', '', '', '', '', '', '', '');
        InsertData('60-1010', XAccountsPayablesRub,
          '60-1010', '44-2990', '91-2330', '91-1330', '91-1330', '', '', '91-2330', '91-1330', '91-2330', '91-1330', '60-1020');
        InsertData('60-1110', XAccountsPayablesCurrency,
          '60-1110', '44-2990', '91-2330', '91-1330', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '60-1120');
        InsertData('60-1210', XAccountsPayablesYE,
          '60-1210', '44-2990', '91-2330', '91-1330', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '60-1220');
        InsertData('60-2000', XAccountsReceivableUnderComission,
          '60-2000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('60-3000', XAccountsPayablesThroughAdvHolders,
          '60-3000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('60-4000', XBillsIssuedAsPaymentForGoods,
          '60-4000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('66-1100', XShortTermCreditsRub,
          '66-1100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('66-1110', XPercentsOnShortTermCreditsRub,
          '66-1110', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('66-1200', XShortTermCreditsCurrency,
          '66-1200', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('66-1210', XPercentsOnShortTermCreditsCurrency,
          '66-1210', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('66-2100', XShortTermLoansRub,
          '66-2100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('66-2110', XPercentsOnShortTermLoansRub,
          '66-2110', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('66-2200', XShortTermLoansCurrency,
          '66-2200', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('66-2210', XPercentsOnShortTermLoansCurrency,
          '66-2210', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('66-3100', XPaperCreditsRub,
          '66-3100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('66-3110', XPercentsOnPaperCreditsCurrency,
          '66-3110', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('66-3200', XPaperCreditsCurrency,
          '66-3200', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('66-3210', XPercentsOnPaperCreditsCurrency,
          '66-3210', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('66-4100', XLoanSecuritiesRub,
          '66-4100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('66-4110', XPercentsOnLoadnSecuritiesRub,
          '66-4110', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('66-4200', XLoanSecuritiesCurrency,
          '66-4200', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('66-4210', XPercentsOnLoanSecuritiesCurrency,
          '66-4210', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '         91-1330', '', '', '');
        InsertData('67-1100', XLongTermCreditsRub,
          '67-1100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('67-1110', XPercentsOnLongTermCreditsRub,
          '67-1110', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('67-1200', XLongTermCreditsCurrency,
          '67-1200', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('67-1210', XPercentsOnLongTermCreditsCurrency,
          '67-1210', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('67-2100', XLongTermLoansRub,
          '67-2100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('67-2110', XPercentsOnLongTermLoansRub,
          '67-2110', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('67-2200', XPercentsOnLongTermLoansCurrency,
          '67-2200', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('67-2210', XPercentsOnLongTermLoansCurrency,
          '67-2210', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('67-3100', XPaperCreditsRub,
          '67-3100', '', '', '', '91-1330', '', '91-2330', '91-1330', '', '', '', '');
        InsertData('67-3110', XPercentsOnPaperCreditsRub,
          '67-3110', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('67-3200', XPaperCreditsCurrency,
          '67-3200', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('67-3210', XPercentsOnPaperCreditsCurrency,
          '67-3210', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('67-4100', XLoanSecuritiesRub,
          '67-4100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('67-4110', XPercentsOnLoanSecuritiesCurrency,
          '67-4110', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('67-4200', XLoanSecuritiesCurrency,
          '67-4200', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('67-4210', XPercentsOnLoanSecuritiesCurrency,
          '67-4210', '', '', '', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '', '', '');
        InsertData('68-1000', XLandTax,
          '68-1000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-2000', XTransportTax,
          '68-2000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-3010', XPTRemittedToFederalBudget,
          '68-3010', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-3020', XPTRemittedToRegionalBudget,
          '68-3020', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-3200', XFinesAndPenaltiesForPT,
          '68-3200', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-4100', XVATRemittedToFederalBudget,
          '68-4100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-4430', XVATForTaxAgent,
          '68-4430', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-4500', XVATFines,
          '68-4500', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-5100', XPhysPersonIncomeTaxForResidents,
          '68-5100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-5200', XPhysPersonIncomeTaxForNonResidents,
          '68-5200', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-6000', XEstateTax,
          '68-6000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-7000', XStateDutiesAndFees,
          '68-7000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-8000', XExciseTax,
          '68-8000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('68-9000', XOtherTaxes,
          '68-9000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('69-1100', XSocialInsuranceAccountsUST,
          '69-1100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('69-1200', XSocialInsuranceAccountsFSS,
          '69-1200', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('69-2200', XPFInsurancePensionPart,
          '69-2200', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('69-2300', XPFAccumulatedPensionPart,
          '69-2300', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('69-3100', XPaymentsToFederalFOMI,
          '69-3100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('69-3200', XPaymentsToLocalFOMI,
          '69-3200', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('70-1000', XPayrollPayments,
          '70-1000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('70-1100', XSalariesAndWagesUnderContrAgr,
          '70-1100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('70-2000', XDividendsPaidToFounders,
          '70-2000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('71-1000', XAdvanceHolderPaymentsRub,
          '71-1000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('71-2001', XAdvanceHolderPaymentsCur1,
          '71-2001', '', '', '', '91-1330', '91-1330', '91-2330', '91-2330', '91-1330', '', '', '');
        InsertData('71-2002', XAdvanceHolderPaymentsCur2,
          '71-2002', '', '', '', '91-1330', '91-1330', '91-2330', '91-2330', '91-1330', '', '', '');
        InsertData('71-2003', XAdvanceHolderPaymentsCur3,
          '71-2003', '', '', '', '91-1330', '91-1330', '91-2330', '91-2330', '91-1330', '', '', '');
        InsertData('73-1000', XIssuedLoans,
          '73-1000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('73-2000', XPropertyDamage,
          '73-2000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('73-9000', XOtherOperations,
          '73-9000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('75-1000', XInvestmentsIntoAuthorisedCapital,
          '75-1000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('75-2000', XIncomePayments,
          '75-2000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('76-1000', XEstateAndPersonalInsurance,
          '76-1000', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('76-2100', XVendorClaims,
          '76-2100', '', '', '', '91-1330', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('76-3000', XDividendsDueAndIncomesDue,
          '76-3000', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('76-4000', XDeponents,
          '76-4000', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('76-5100', XSecuritiesPurchaseContracts,
          '76-5100', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('76-5110', XPercentsOnSecuritiesPurchContracts,
          '76-5110', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('76-5300', XAccountingOfExpUnderComission,
          '76-5300', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('76-5400', XNonInterestLoans,
          '76-5400', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('76-5500', XLease,
          '76-5500', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('76-5600', XOtherFinancialInvestments,
          '76-5600', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('76-5700', XContractorsAgreements,
          '76-5700', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('79-1000', XDedicatedProperty,
          '79-1000', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('79-2000', XOngoingOperations,
          '79-2000', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('79-3000', XTrustManagingContracts,
          '79-3000', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('80-2000', XShareCapital,
          '80-2000', '', '', '', '91-1330', '', '', '91-1330', '91-2330', '', '', '');
        InsertData('99-9999', XVendorOffBalanceAccounts,
          '99-1009', '', '', '', '', '', '', '', '', '', '', '');
        // test automation
        InsertData(XTEST, XTEST,
          '60-1110', '44-2990', '91-2330', '91-1330', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '91-2330', '91-1330', '60-1120');
    end;

    var
        XDepositsLessThenYear: Label 'Deposits < 1 year';
        XDepositsMoreThenYear: Label 'Deposits > 1 year';
        XSharesOfSubAndChildCompanies: Label 'Shares of subsidiaries and child companies';
        XShortTermLoansGranted: Label 'Short-term loans granted';
        XAccountsPayablesRub: Label 'Accounts Payables, rub.';
        XAccountsPayablesCurrency: Label 'Accounts Payables, currency';
        XAccountsPayablesYE: Label 'Accounts Payables, y.e.';
        XAccountsReceivableUnderComission: Label 'Accounts receivable under comission contracts';
        XAccountsPayablesThroughAdvHolders: Label 'Accounts payables through advance holders';
        XBillsIssuedAsPaymentForGoods: Label 'Bills issued as payment for goods';
        XShortTermCreditsRub: Label 'Short-term credits, rub.';
        XPercentsOnShortTermCreditsRub: Label '%% on short-term credits, rub.';
        XShortTermCreditsCurrency: Label 'Short-term credits, currency';
        XPercentsOnShortTermCreditsCurrency: Label '%% on short-term credits, currency';
        XShortTermLoansRub: Label 'Short-term loans, rub.';
        XPercentsOnShortTermLoansRub: Label '%% on short-term loans, rub.';
        XShortTermLoansCurrency: Label 'Short-term loans, currency';
        XPercentsOnShortTermLoansCurrency: Label '%% on short-term loans, currency';
        XPaperCreditsRub: Label 'Paper credits, rub.';
        XPercentsOnPaperCreditsRub: Label '%% on paper credits, rub.';
        XPaperCreditsCurrency: Label 'Paper credits, currency';
        XPercentsOnPaperCreditsCurrency: Label '%% on paper credits, currency';
        XLoanSecuritiesRub: Label 'Loan securities, rub.';
        XPercentsOnLoadnSecuritiesRub: Label '%% on Loan securities, rub.';
        XLoanSecuritiesCurrency: Label 'Loan securities, currency';
        XPercentsOnLoanSecuritiesCurrency: Label '%% on Loan securities, currency';
        XLongTermCreditsRub: Label 'Long-term credits, rub.';
        XPercentsOnLongTermCreditsRub: Label '%% on Long-term credits, rub.';
        XLongTermCreditsCurrency: Label 'Long-term credits, currency';
        XPercentsOnLongTermCreditsCurrency: Label '%% on Long-term credits, currency';
        XLongTermLoansRub: Label 'Long-term loans, rub.';
        XPercentsOnLongTermLoansRub: Label '%% on Long-term loans, rub.';
        XPercentsOnLongTermLoansCurrency: Label '%% on Long-term loans, currency';
        XLandTax: Label 'Land tax';
        XTransportTax: Label 'Transport tax';
        XPTRemittedToFederalBudget: Label 'PT remitted to federal budget';
        XPTRemittedToRegionalBudget: Label 'PT remitted to regional budget';
        XFinesAndPenaltiesForPT: Label 'Fines and penalties for PT';
        XVATRemittedToFederalBudget: Label 'VAT remitted to federal budget';
        XVATForTaxAgent: Label 'VAT for tax agent';
        XVATFines: Label 'VAT fines';
        XPhysPersonIncomeTaxForResidents: Label 'Physical person income tax (residents)';
        XPhysPersonIncomeTaxForNonResidents: Label 'Physical person income tax (non residents)';
        XEstateTax: Label 'Estate tax';
        XStateDutiesAndFees: Label 'State duties and fees';
        XExciseTax: Label 'Excise';
        XOtherTaxes: Label 'Other taxes';
        XSocialInsuranceAccountsUST: Label 'Social insurance accounts. UST.';
        XSocialInsuranceAccountsFSS: Label 'Social insurance accounts. FSS.';
        XPFInsurancePensionPart: Label 'PF insurance pension part';
        XPFAccumulatedPensionPart: Label 'PF accumulated pension part';
        XPaymentsToFederalFOMI: Label 'Payments to fedetal FOMI';
        XPaymentsToLocalFOMI: Label 'Payments to local FOMI';
        XPayrollPayments: Label 'Payroll Payments';
        XSalariesAndWagesUnderContrAgr: Label 'Salaries and wages under contractor agreements';
        XDividendsPaidToFounders: Label 'Dividends paid to founders';
        XAdvanceHolderPaymentsRub: Label 'Advance holder payments, rub.';
        XAdvanceHolderPaymentsCur1: Label 'Advance holder payments, currency 1';
        XAdvanceHolderPaymentsCur2: Label 'Advance holder payments, currency 2';
        XAdvanceHolderPaymentsCur3: Label 'Advance holder payments, currency 3';
        XIssuedLoans: Label 'Issued Loans';
        XPropertyDamage: Label 'Property damage';
        XOtherOperations: Label 'Other operations';
        XInvestmentsIntoAuthorisedCapital: Label 'Investments into authorised capital';
        XIncomePayments: Label 'Income payments';
        XEstateAndPersonalInsurance: Label 'Estate and personal insurance';
        XVendorClaims: Label 'Vendor claims';
        XDividendsDueAndIncomesDue: Label 'Dividends due and incomes due';
        XDeponents: Label 'Deponents';
        XSecuritiesPurchaseContracts: Label 'Securities purchase contracts';
        XPercentsOnSecuritiesPurchContracts: Label '%% on Securities purchase contracts';
        XAccountingOfExpUnderComission: Label 'Accounting of expenses under comission contracts';
        XNonInterestLoans: Label 'Non-interest loans';
        XLease: Label 'Lease';
        XOtherFinancialInvestments: Label 'Other financial investments';
        XContractorsAgreements: Label 'Contractor''s agreements';
        XTrustManagingContracts: Label 'Trust managing contracts';
        XDedicatedProperty: Label 'Dedicated property';
        XOngoingOperations: Label 'On-going operations';
        XShareCapital: Label 'Share capital';
        XVendorOffBalanceAccounts: Label 'Vendor off-balance accounts';
        XTEST: Label '_TEST';

    procedure InsertData("Code": Code[10]; Description: Text[50]; "Payables Account": Code[20]; ServiceChargeAcc: Code[20]; "Pmt. Disc. Debit Acc.": Code[20]; "Pmt. Disc. Credit Acc.": Code[20]; "Invoice Rounding Account": Code[20]; "Debit Curr. Appln. Rndg. Acc.": Code[20]; "Credit Curr. Appln. Rndg. Acc.": Code[20]; "Debit Rounding Account": Code[20]; "Credit Rounding Account": Code[20]; "Payment Tolerance Debit Acc.": Code[20]; "Payment Tolerance Credit Acc.": Code[20]; "Prepayment Account": Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        VendorPostingGroup.Init();
        VendorPostingGroup.Validate(Code, Code);
        VendorPostingGroup.Validate(Description, Description);
        VendorPostingGroup.Validate("Payables Account", MakeAdjustments.Convert("Payables Account"));
        VendorPostingGroup.Validate("Service Charge Acc.", MakeAdjustments.Convert(ServiceChargeAcc));
        VendorPostingGroup.Validate("Payment Disc. Debit Acc.", MakeAdjustments.Convert("Pmt. Disc. Debit Acc."));
        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", MakeAdjustments.Convert("Pmt. Disc. Credit Acc."));
        VendorPostingGroup.Validate("Invoice Rounding Account", MakeAdjustments.Convert("Invoice Rounding Account"));
        VendorPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Credit Curr. Appln. Rndg. Acc."));
        VendorPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Debit Curr. Appln. Rndg. Acc."));
        VendorPostingGroup.Validate("Credit Rounding Account", MakeAdjustments.Convert("Credit Rounding Account"));
        VendorPostingGroup.Validate("Debit Rounding Account", MakeAdjustments.Convert("Debit Rounding Account"));
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", MakeAdjustments.Convert("Payment Tolerance Debit Acc."));
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", MakeAdjustments.Convert("Payment Tolerance Credit Acc."));
        VendorPostingGroup.Validate("Prepayment Account", MakeAdjustments.Convert("Prepayment Account"));
        VendorPostingGroup.Insert();
    end;
}

