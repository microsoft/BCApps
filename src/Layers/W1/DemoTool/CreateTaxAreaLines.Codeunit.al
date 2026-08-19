codeunit 101319 "Create Tax Area Lines"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if (DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax") and
           (DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Standard)
        then begin
            InsertData(XATLANTAGA, XGA, 0);
            InsertData(XATLANTAGA, XGAATLANTA, 0);
            InsertData(XATLANTAGA, XGAFULTON, 0);
            InsertData(XCHICAGOIL, XIL, 0);
            InsertData(XCHICAGOIL, XILCHICAGO, 0);
            InsertData(XCHICAGOIL, XILCOOK, 0);
            if DemoDataSetup."Advanced Setup" then begin
                InsertData(XMIAMIFL, XFL, 1);
                InsertData(XMIAMIFL, XFLDADE, 2);
                InsertData(XMIAMIFL, XFLMIAMI, 3);
            end else begin
                InsertData(XMIAMIFL, XFL, 0);
                InsertData(XMIAMIFL, XFLDADE, 0);
                InsertData(XMIAMIFL, XFLMIAMI, 0);
            end;
            InsertData(XNATLGA, XGA, 0);
            InsertData(XNATLGA, XGAATLANTA, 0);
            InsertData(XNATLGA, XGAFULTON, 0);
            InsertData(XNATLGA, XGAMARTA, 0);
        end;
    end;

    var
        "Tax Area Line": Record "Tax Area Line";
        DemoDataSetup: Record "Demo Data Setup";
        XATLANTAGA: Label 'ATLANTA, GA';
        XGA: Label 'GA';
        XGAATLANTA: Label 'GAATLANTA';
        XCHICAGOIL: Label 'CHICAGO, IL';
        XIL: Label 'IL';
        XILCHICAGO: Label 'ILCHICAGO';
        XILCOOK: Label 'ILCOOK';
        XMIAMIFL: Label 'MIAMI, FL';
        XFL: Label 'FL';
        XFLDADE: Label 'FLDADE';
        XNATLGA: Label 'N.ATL., GA';
        XGAFULTON: Label 'GAFULTON';
        XFLMIAMI: Label 'FLMIAMI';
        XGAMARTA: Label 'GAMARTA';

    procedure InsertData("Tax Area": Code[20]; "Tax Jurisdiction Code": Code[20]; "Calculation Order": Integer)
    begin
        "Tax Area Line".Init();
        "Tax Area Line".Validate("Tax Area", "Tax Area");
        "Tax Area Line".Validate("Tax Jurisdiction Code", "Tax Jurisdiction Code");
        "Tax Area Line".Validate("Calculation Order", "Calculation Order");
        "Tax Area Line".Insert();
    end;
}

