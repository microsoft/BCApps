codeunit 117058 "Create Service Zone"
{

    trigger OnRun()
    begin
        InsertData(XE, XEast);
        InsertData(XM, XMidland);
        InsertData(XN, XNorth);
        InsertData(XS, XSouth);
        InsertData(XSE, XSouthEast);
        InsertData(XW, XWest);
        InsertData(XX, XInternationalothercountries);
    end;

    var
        XE: Label 'E';
        XEast: Label 'East';
        XM: Label 'M';
        XMidland: Label 'Midland';
        XN: Label 'N';
        XNorth: Label 'North';
        XS: Label 'S';
        XSouth: Label 'South';
        XSE: Label 'SE';
        XSouthEast: Label 'South East';
        XW: Label 'W';
        XWest: Label 'West';
        XX: Label 'X';
        XInternationalothercountries: Label 'International, other countries';

    procedure InsertData("Code": Text[250]; Description: Text[250])
    var
        ServiceZone: Record "Service Zone";
    begin
        ServiceZone.Init();
        ServiceZone.Validate(Code, Code);
        ServiceZone.Validate(Description, Description);
        ServiceZone.Insert(true);
    end;
}

