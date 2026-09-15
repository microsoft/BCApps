codeunit 101320 "Create Tax Jurisdictions"
{

    trigger OnRun()
    var
        AdjForPmtDisc: Boolean;
        CalculateTaxOnTax: Boolean;
    begin
        DemoDataSetup.Get();
        if (DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax") and
           (DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Standard)
        then begin
            AdjForPmtDisc := DemoDataSetup."Adjust for Payment Discount";
            CalculateTaxOnTax := DemoDataSetup."Advanced Setup";

            InsertData(XFL, XStateofFlorida, '995611', '995631', XFL, '995621', CalculateTaxOnTax, false);
            InsertData(XFLDADE, XDadeCountycommaFL, '995611', '995631', XFL, '995621', CalculateTaxOnTax, false);
            InsertData(XFLMIAMI, XCityofMiamicommaFL, '995611', '995631', XFL, '995621', CalculateTaxOnTax, false);
            InsertData(XGA, XStateofGeorgia, '995610', '995630', XGA, '995620', false, false);
            InsertData(XGAATLANTA, XCityofAtlantacommaGA, '995610', '995630', XGA, '995620', false, false);
            InsertData(XGAFULTON, XFultonCountycommaGA, '995610', '995630', XGA, '995620', false, false);
            InsertData(XGAGWINNETT, XGwinnettCountycommaGA, '995610', '995630', XGA, '995620', false, false);
            InsertData(XGAMARTA, XMartaDistrictcommaGA, '995610', '995630', XGA, '995620', false, false);
            InsertData(XIL, XStateofIllinois, '995612', '995632', XIL, '995622', false, AdjForPmtDisc);
            InsertData(XILCHICAGO, XCityofChicagocommaIL, '995612', '995632', XIL, '995622', false, AdjForPmtDisc);
            InsertData(XILCOOK, XCOOKCountycommaIL, '995612', '995632', XIL, '995622', false, AdjForPmtDisc);

            InsertLocalData();
        end;
    end;

    var
        "Tax Jurisdiction": Record "Tax Jurisdiction";
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        XFL: Label 'FL';
        XStateofFlorida: Label 'State of Florida';
        XFLDADE: Label 'FLDADE';
        XDadeCountycommaFL: Label 'Dade County, FL';
        XCityofMiamicommaFL: Label 'City of Miami, FL';
        XGA: Label 'GA';
        XStateofGeorgia: Label 'State of Georgia';
        XFLMIAMI: Label 'FLMIAMI';
        XGAATLANTA: Label 'GAATLANTA';
        XCityofAtlantacommaGA: Label 'City of Atlanta, GA';
        XGAFULTON: Label 'GAFULTON';
        XFultonCountycommaGA: Label 'Fulton County, GA';
        XGAGWINNETT: Label 'GAGWINNETT';
        XGwinnettCountycommaGA: Label 'Gwinnett County, GA';
        XGAMARTA: Label 'GAMARTA';
        XMartaDistrictcommaGA: Label 'Marta District, GA';
        XIL: Label 'IL';
        XStateofIllinois: Label 'State of Illinois';
        XILCHICAGO: Label 'ILCHICAGO';
        XCityofChicagocommaIL: Label 'City of Chicago, IL';
        XILCOOK: Label 'ILCOOK';
        XCOOKCountycommaIL: Label 'COOK County, IL';

    procedure InsertData("Code": Code[20]; Description: Text[30]; "Tax Account (Sales)": Code[20]; "Tax Account (Purchases)": Code[20]; "Report-to Jurisdiction": Code[20]; "Reverse Charge (Purchases)": Code[20]; "Calculate Tax on Tax": Boolean; AdjustForPaymentDiscount: Boolean)
    begin
        "Tax Jurisdiction".Init();
        "Tax Jurisdiction".Validate(Code, Code);
        "Tax Jurisdiction".Insert();
        "Tax Jurisdiction".Validate(Description, Description);
        "Tax Jurisdiction".Validate("Tax Account (Sales)", CA.Convert("Tax Account (Sales)"));
        "Tax Jurisdiction".Validate("Tax Account (Purchases)", CA.Convert("Tax Account (Purchases)"));
        "Tax Jurisdiction".Validate("Report-to Jurisdiction", "Report-to Jurisdiction");
        "Tax Jurisdiction".Validate("Reverse Charge (Purchases)", CA.Convert("Reverse Charge (Purchases)"));
        if DemoDataSetup."Advanced Setup" then begin
            "Tax Jurisdiction".Validate("Unreal. Tax Acc. (Sales)", CA.Convert('995615'));
            "Tax Jurisdiction".Validate("Unreal. Tax Acc. (Purchases)", CA.Convert('995635'));
            "Tax Jurisdiction".Validate("Unreal. Rev. Charge (Purch.)", CA.Convert('995625'));
            "Tax Jurisdiction".Validate("Unrealized VAT Type", "Tax Jurisdiction"."Unrealized VAT Type"::Percentage);
        end;
        "Tax Jurisdiction".Validate("Calculate Tax on Tax", "Calculate Tax on Tax");
        "Tax Jurisdiction".Validate("Adjust for Payment Discount", AdjustForPaymentDiscount);
        "Tax Jurisdiction".Modify();
    end;

    local procedure InsertLocalData()
    begin
    end;
}

