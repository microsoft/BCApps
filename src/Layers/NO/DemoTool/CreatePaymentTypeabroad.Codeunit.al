codeunit 160806 "Create Payment Type (abroad)"
{

    trigger OnRun()
    begin
        InsertData('14', XPurchaseSaleofItems);
        InsertData('26', XRental);
        InsertData('29', XOtherPuerchasSaleofServices);
        InsertData('31', XInterests);
        InsertData('35', XYield);
        InsertData('38', XOtherreturnoncapital);
        InsertData('41', XPurchaseSaleofRealEstate);
        InsertData('43', XDirectInvestmentinShares);
        InsertData('45', XDirectInvestmentOtherCapital);
        InsertData('51', XPortfolioInvestmentinShares);
        InsertData('52', XPortfolioInvestmentinBonds);
        InsertData('53', XPortfolioInvestmentinDerivat);
        InsertData('71', XLifeInsurancePension);
        InsertData('79', XOtherFinancialIinvestments);
        InsertData('81', XSalary);
        InsertData('82', XInheritanceGifts);
    end;

    var
        PmtTypeAbroad: Record "Payment Type Code Abroad";
        XPurchaseSaleofItems: Label 'Purchase/sale of items';
        XRental: Label 'Rental';
        XOtherPuerchasSaleofServices: Label 'Other Purchase/Sale of services';
        XInterests: Label 'Interests';
        XYield: Label 'Yield';
        XOtherreturnoncapital: Label 'Other return on capital';
        XPurchaseSaleofRealEstate: Label 'Purchase/Sale of real estate and activated rights abroad';
        XDirectInvestmentinShares: Label 'Direct investment in shares etc.';
        XDirectInvestmentOtherCapital: Label 'Direct investment in other capital';
        XPortfolioInvestmentinShares: Label 'Portfolio investment in shares and securities';
        XPortfolioInvestmentinBonds: Label 'Portfolio investment in bonds and certificates';
        XPortfolioInvestmentinDerivat: Label 'Portfolio investment in derivatives';
        XLifeInsurancePension: Label 'Life insurance/pension';
        XOtherFinancialIinvestments: Label 'Other financial investments';
        XSalary: Label 'Salary';
        XInheritanceGifts: Label 'Inheritance, gifts and more';

    procedure InsertData(Name: Code[2]; Description: Text[80])
    begin
        PmtTypeAbroad.Init();
        PmtTypeAbroad.Code := Name;
        PmtTypeAbroad.Description := Description;
        PmtTypeAbroad.Insert();
    end;
}

