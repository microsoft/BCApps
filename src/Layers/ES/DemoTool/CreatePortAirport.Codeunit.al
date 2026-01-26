codeunit 161001 "Create Port/Airport"
{

    trigger OnRun()
    begin
        InsertData('0801', XBarcelonaAirport);
        InsertData('0811', XBarcelonaMaritimeImport);
        InsertData('0812', XBarcelonaMaritimeExport);
        InsertData('2801', XMadridAirport);
        InsertData('4601', XValenciaAirport);
        InsertData('4611', XValenciaMaritime);
        InsertData('4621', XSaguntoMaritime);
        InsertData('4631', XGandiaMaritimeTxt);
    end;

    var
        PortAirport: Record "Entry/Exit Point";
        XBarcelonaAirport: Label 'Barcelona Airport';
        XBarcelonaMaritimeImport: Label 'Barcelona Maritime Import';
        XBarcelonaMaritimeExport: Label 'Barcelona Maritime Export';
        XMadridAirport: Label 'Madrid Airport';
        XValenciaAirport: Label 'Valencia Airport';
        XValenciaMaritime: Label 'Valencia Maritime';
        XSaguntoMaritime: Label 'Sagunto Maritime';
        XGandiaMaritimeTxt: Label 'Gandía Maritime';

    procedure InsertData("Code": Code[10]; Text: Text[30])
    begin
        PortAirport.Init();
        PortAirport.Validate(Code, Code);
        PortAirport.Validate(Description, Text);
        PortAirport.Insert();
    end;
}

