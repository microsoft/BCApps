codeunit 101322 "Create Tax Details"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if (DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax") and
           (DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Standard)
        then begin
            InsertData(XFL, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);
            InsertData(XFL, XFURNITURE, 0, 19010101D, 0, 5, 0, false);
            InsertData(XFL, XLABOR, 0, 19010101D, 0, 1, 0, false);
            InsertData(XFL, XMATERIALS, 0, 19010101D, 0, 3, 0, false);
            InsertData(XFL, XSUPPLIES, 0, 19010101D, 0, 2, 0, false);
            InsertData(XFLDADE, '', 0, 19010101D, 0, 1, 0, false);
            InsertData(XFLDADE, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);
            InsertData(XFLMIAMI, '', 0, 19010101D, 0, 1, 0, false);
            InsertData(XFLMIAMI, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);
            InsertData(XFLMIAMI, XSUPPLIES, 0, 19010101D, 0, 0, 0, false);
            InsertData(XGA, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);
            InsertData(XGA, XFURNITURE, 0, 19010101D, 0, 3, 0, false);
            InsertData(XGA, XLABOR, 0, 19010101D, 0, 0, 0, false);
            InsertData(XGA, XMATERIALS, 0, 19010101D, 0, 2, 0, false);
            InsertData(XGA, XSUPPLIES, 0, 19010101D, 0, 2, 0, false);
            InsertData(XGAATLANTA, '', 0, 19010101D, 0, 1, 0, false);
            InsertData(XGAATLANTA, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);
            InsertData(XGAFULTON, '', 0, 19010101D, 0, 2, 0, false);
            InsertData(XGAFULTON, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);
            InsertData(XGAGWINNETT, '', 0, 19010101D, 0, 2, 0, false);
            InsertData(XGAGWINNETT, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);
            InsertData(XGAMARTA, '', 0, 19010101D, 0, 1, 0, false);
            InsertData(XGAMARTA, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);
            InsertData(XIL, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);
            InsertData(XIL, XFURNITURE, 0, 19010101D, 0, 3, 0, false);
            InsertData(XIL, XLABOR, 0, 19010101D, 0, 1, 0, false);
            InsertData(XIL, XMATERIALS, 0, 19010101D, 0, 4, 0, false);
            InsertData(XIL, XSUPPLIES, 0, 19010101D, 0, 2, 0, false);
            InsertData(XILCHICAGO, '', 0, 19010101D, 0, 1, 0, false);
            InsertData(XILCHICAGO, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);
            InsertData(XILCOOK, '', 0, 19010101D, 0, 1, 0, false);
            InsertData(XILCOOK, XNONTAXABLETok, 0, 19010101D, 0, 0, 0, false);

            InsertLocalData();
        end;
    end;

    var
        "Tax Detail": Record "Tax Detail";
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        XFL: Label 'FL';
        XFURNITURE: Label 'FURNITURE';
        XLABOR: Label 'LABOR';
        XMATERIALS: Label 'MATERIALS';
        XSUPPLIES: Label 'SUPPLIES';
        XFLDADE: Label 'FLDADE';
        XFLMIAMI: Label 'FLMIAMI';
        XGA: Label 'GA';
        XGAATLANTA: Label 'GAATLANTA';
        XGAFULTON: Label 'GAFULTON';
        XGAGWINNETT: Label 'GAGWINNETT';
        XGAMARTA: Label 'GAMARTA';
        XIL: Label 'IL';
        XILCHICAGO: Label 'ILCHICAGO';
        XILCOOK: Label 'ILCOOK';
        XNONTAXABLETok: Label 'NonTAXABLE';

    procedure InsertData("Tax Jurisdiction Code": Code[20]; "Tax Group Code": Code[10]; "Tax Type": Integer; "Effective Date": Date; "Maximum Amount/Qty.": Decimal; "Tax Below Maximum": Decimal; "Tax Above Maximum": Decimal; "Calculate Tax on Tax": Boolean)
    begin
        "Tax Detail".Init();
        "Tax Detail".Validate("Tax Jurisdiction Code", "Tax Jurisdiction Code");
        "Tax Detail".Validate("Tax Group Code", "Tax Group Code");
        "Tax Detail".Validate("Tax Type", "Tax Type");
        "Tax Detail".Validate("Effective Date", CA.AdjustDate("Effective Date"));
        "Tax Detail".Validate("Maximum Amount/Qty.", "Maximum Amount/Qty.");
        "Tax Detail".Validate("Tax Below Maximum", "Tax Below Maximum");
        "Tax Detail".Validate("Tax Above Maximum", "Tax Above Maximum");
        "Tax Detail".Validate("Calculate Tax on Tax", "Calculate Tax on Tax");
        "Tax Detail".Insert();
    end;

    local procedure InsertLocalData()
    begin
    end;
}

