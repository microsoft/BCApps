codeunit 161559 "Create CH VAT Cipher Setup"
{

    trigger OnRun()
    var
        VATCipherSetup: Record "VAT Cipher Setup";
    begin
        VATCipherSetup.Init();

        CreateVATCipherCode(VATCipherSetup."Total Revenue", '200', TotalTurnoverTxt);
        CreateVATCipherCode(VATCipherSetup."Revenue of Non-Tax. Services", '205', RevenueNonTaxTxt);
        CreateVATCipherCode(VATCipherSetup."Deduction of Tax-Exempt", '220', DeductionTaxExemptTxt);
        CreateVATCipherCode(VATCipherSetup."Deduction of Services Abroad", '221', DeductionServicesAbroadTxt);
        CreateVATCipherCode(VATCipherSetup."Deduction of Transfer", '225', DeductionOfTransferTxt);
        CreateVATCipherCode(VATCipherSetup."Deduction of Non-Tax. Services", '230', DeductionNonTaxTxt);
        CreateVATCipherCode(VATCipherSetup."Reduction in Payments", '235', ReductionInPaymentsTxt);
        CreateVATCipherCode(VATCipherSetup.Miscellaneous, '280', MiscellaneousTxt);
        CreateVATCipherCode(VATCipherSetup."Total Deductions", '289', TotalDeductionsTxt);
        CreateVATCipherCode(VATCipherSetup."Total Taxable Revenue", '299', TotalTaxableTurnoverTxt);

        CreateVATCipherCode(VATCipherSetup."Tax Normal Rate Serv. Before", '302', TaxServicesAtNormalRateBeforePeriodTxt);
        CreateVATCipherCode(VATCipherSetup."Tax Normal Rate Serv. After", '303', TaxServicesAtNormalRateFromPeriodTxt);
        CreateVATCipherCode(VATCipherSetup."Tax Reduced Rate Serv. Before", '312', TaxServicesAtReducedRateBeforePeriodTxt);
        CreateVATCipherCode(VATCipherSetup."Tax Reduced Rate Serv. After", '313', TaxServicesAtReducedRateFromPeriodTxt);
        CreateVATCipherCode(VATCipherSetup."Tax Hotel Rate Serv. Before", '342', TaxServicesAtHotelRateBeforePeriodTxt);
        CreateVATCipherCode(VATCipherSetup."Tax Hotel Rate Serv. After", '343', TaxServicesAtHotelRateFromPeriodTxt);
        CreateVATCipherCode(VATCipherSetup."Acquisition Tax Before", '382', AcquisitionTaxBeforePeriodTxt);
        CreateVATCipherCode(VATCipherSetup."Acquisition Tax After", '383', AcquisitionTaxFromPeriodTxt);
        CreateVATCipherCode(VATCipherSetup."Total Owned Tax", '399', TotalOwnedTaxTxt);

        CreateVATCipherCode(VATCipherSetup."Input Tax on Material and Serv", '400', InputTaxOnCostTxt);
        CreateVATCipherCode(VATCipherSetup."Input Tax on Investsments", '405', InputTaxOnInvestmentsTxt);
        CreateVATCipherCode(VATCipherSetup."Deposit Tax", '410', DeTaxationTxt);
        CreateVATCipherCode(VATCipherSetup."Input Tax Corrections", '415', CorrectionOfInputTaxDeductionTxt);
        CreateVATCipherCode(VATCipherSetup."Input Tax Cutbacks", '420', ReductionOfInputTaxDeductionTxt);
        CreateVATCipherCode(VATCipherSetup."Total Input Tax", '479', TotalAmountOfTaxDueTxt);

        CreateVATCipherCode(VATCipherSetup."Tax Amount to Pay", '500', AmountToBePaidTxt);
        CreateVATCipherCode(VATCipherSetup."Credit of Taxable Person", '510', CreditOfTaxablePersonTxt);
        CreateVATCipherCode(VATCipherSetup."Cash Flow Taxes", '900', CashFlowTaxesTxt);
        CreateVATCipherCode(VATCipherSetup."Cash Flow Compensations", '910', CashFlowCompensationsTxt);

        VATCipherSetup.Insert();
    end;

    var
        TotalTurnoverTxt: Label 'Total amount of agreed or collected consideration';
        RevenueNonTaxTxt: Label 'Revenue of non-taxable services';
        DeductionTaxExemptTxt: Label 'Deduction of tax-exempt services';
        DeductionServicesAbroadTxt: Label 'Deduction of services abroad';
        DeductionOfTransferTxt: Label 'Deduction of transfer';
        DeductionNonTaxTxt: Label 'Deduction of non-taxable services';
        ReductionInPaymentsTxt: Label 'Reduction in payments';
        MiscellaneousTxt: Label 'Miscellaneous taxation';
        TotalDeductionsTxt: Label 'Total deductions';
        TotalTaxableTurnoverTxt: Label 'Total taxable turnover';
        TaxServicesAtNormalRateBeforePeriodTxt: Label 'Tax services at normal rate before period';
        TaxServicesAtNormalRateFromPeriodTxt: Label 'Tax services at normal rate from period';
        TaxServicesAtReducedRateBeforePeriodTxt: Label 'Tax services at reduced rate before period';
        TaxServicesAtReducedRateFromPeriodTxt: Label 'Tax services at reduced rate from period';
        TaxServicesAtHotelRateBeforePeriodTxt: Label 'Tax services at hotel rate before period';
        TaxServicesAtHotelRateFromPeriodTxt: Label 'Tax services at hotel rate from period';
        AcquisitionTaxBeforePeriodTxt: Label 'Acquisition tax before period';
        AcquisitionTaxFromPeriodTxt: Label 'Acquisition tax from period';
        TotalOwnedTaxTxt: Label 'Total owned tax';
        InputTaxOnCostTxt: Label 'Input tax on cost of materials and services';
        InputTaxOnInvestmentsTxt: Label 'Input tax on investments';
        DeTaxationTxt: Label 'De-taxation';
        CorrectionOfInputTaxDeductionTxt: Label 'Correction of the input tax deduction';
        ReductionOfInputTaxDeductionTxt: Label 'Reduction of the input tax deduction';
        TotalAmountOfTaxDueTxt: Label 'Total amount of tax due';
        AmountToBePaidTxt: Label 'Amount to be paid';
        CreditOfTaxablePersonTxt: Label 'Credit in favour of the taxable person';
        CashFlowTaxesTxt: Label 'Cash flow taxes: subsidies, funds';
        CashFlowCompensationsTxt: Label 'Cash flow compensations: donations, dividends';

    local procedure CreateVATCipherCode(var VATCipherField: Code[20]; "Code": Code[20]; Description: Text[50])
    var
        VATCipherCode: Record "VAT Cipher Code";
    begin
        VATCipherCode.Init();
        VATCipherCode.Code := Code;
        VATCipherCode.Description := Description;
        VATCipherCode.Insert();
        VATCipherField := Code;
    end;
}

