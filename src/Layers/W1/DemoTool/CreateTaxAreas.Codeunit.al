codeunit 101318 "Create Tax Areas"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if (DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax") and
           (DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Standard)
        then begin
            InsertData(XATLANTAGA, XATLANTAGA);
            InsertData(XCHICAGOIL, XCHICAGOIL);
            InsertData(XMIAMIFL, XMIAMIFL);
            InsertData(XNATLGA, XAtlantaGANorth);
        end;
    end;

    var
        "Tax Area": Record "Tax Area";
        DemoDataSetup: Record "Demo Data Setup";
        XATLANTAGA: Label 'ATLANTA, GA';
        XCHICAGOIL: Label 'CHICAGO, IL';
        XMIAMIFL: Label 'MIAMI, FL';
        XNATLGA: Label 'N.ATL., GA';
        XAtlantaGANorth: Label 'Atlanta, GA - North';

    procedure InsertData("Code": Code[20]; Description: Text[30])
    begin
        "Tax Area".Init();
        "Tax Area".Validate(Code, Code);
        "Tax Area".Validate(Description, Description);
        "Tax Area".Insert();
    end;
}

