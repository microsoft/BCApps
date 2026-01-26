codeunit 101320 "Create Tax Jurisdictions"
{

    trigger OnRun()
    var
        AdjForPmtDisc: Boolean;
        CalculateTaxOnTax: Boolean;
        TaxAccount: Code[20];
        ReverseChargeAccount: Code[20];
    begin
        DemoDataSetup.Get();
        GetAccounts(TaxAccount, ReverseChargeAccount);
        UpdateTaxSetup(TaxAccount, ReverseChargeAccount);
        if (DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax") and
           (DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Standard)
        then begin
            AdjForPmtDisc := DemoDataSetup."Adjust for Payment Discount";
            CalculateTaxOnTax := DemoDataSetup."Advanced Setup";
            InsertData(XFL, XStateofFlorida, TaxAccount, TaxAccount, XFL, ReverseChargeAccount, CalculateTaxOnTax, false);
            InsertData(XFLDADE, XDadeCountycommaFL, TaxAccount, TaxAccount, XFL, ReverseChargeAccount, CalculateTaxOnTax, false);
            InsertData(XFLMIAMI, XCityofMiamicommaFL, TaxAccount, TaxAccount, XFL, ReverseChargeAccount, CalculateTaxOnTax, false);
            InsertData(XGA, XStateofGeorgia, TaxAccount, TaxAccount, XGA, ReverseChargeAccount, false, false);
            InsertData(XGAATLANTA, XCityofAtlantacommaGA, TaxAccount, TaxAccount, XGA, ReverseChargeAccount, false, false);
            InsertData(XGAFULTON, XFultonCountycommaGA, TaxAccount, TaxAccount, XGA, ReverseChargeAccount, false, false);
            InsertData(XGAGWINNETT, XGwinnettCountycommaGA, TaxAccount, TaxAccount, XGA, ReverseChargeAccount, false, false);
            InsertData(XGAMARTA, XMartaDistrictcommaGA, TaxAccount, TaxAccount, XGA, ReverseChargeAccount, false, false);
            InsertData(XIL, XStateofIllinois, TaxAccount, TaxAccount, XIL, ReverseChargeAccount, false, AdjForPmtDisc);
            InsertData(XILCHICAGO, XCityofChicagocommaIL, TaxAccount, TaxAccount, XIL, ReverseChargeAccount, false, AdjForPmtDisc);
            InsertData(XILCOOK, XCOOKCountycommaIL, TaxAccount, TaxAccount, XIL, ReverseChargeAccount, false, AdjForPmtDisc);

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
            "Tax Jurisdiction".Validate("Unreal. Tax Acc. (Sales)", '');
            "Tax Jurisdiction".Validate("Unreal. Tax Acc. (Purchases)", '');
            "Tax Jurisdiction".Validate("Unreal. Rev. Charge (Purch.)", '');
            "Tax Jurisdiction".Validate("Unrealized VAT Type", 0);
        end;
        "Tax Jurisdiction".Validate("Calculate Tax on Tax", "Calculate Tax on Tax");
        "Tax Jurisdiction".Validate("Adjust for Payment Discount", AdjustForPaymentDiscount);
        "Tax Jurisdiction".Modify();
    end;

    local procedure InsertLocalData()
    begin
    end;

    local procedure UpdateTaxSetup(TaxAccount: Code[20]; ReverseChargeAccount: Code[20])
    var
        TaxSetup: Record "Tax Setup";
    begin
        TaxSetup.Get();
        TaxSetup."Tax Account (Sales)" := CA.Convert(TaxAccount);
        TaxSetup."Tax Account (Purchases)" := CA.Convert(TaxAccount);
        TaxSetup."Reverse Charge (Purchases)" := ReverseChargeAccount;
        TaxSetup.Modify();
    end;

    local procedure GetAccounts(var TaxAccount: Code[20]; var ReverseChargeAccount: Code[20])
    var
        CreateGLAccount: Codeunit "Create G/L Account";
    begin
        case DemoDataSetup."Data Type" of
            DemoDataSetup."Data Type"::Extended:
                begin
                    TaxAccount := '995710';
                    ReverseChargeAccount := '995620';
                end;
            else begin
                TaxAccount := CreateGLAccount.TaxesLiable();
                ReverseChargeAccount := CreateGLAccount.TaxesLiable();
            end;
        end;
    end;
}

