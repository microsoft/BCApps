codeunit 118834 "Create Warehouse Classes"
{

    trigger OnRun()
    begin
        InsertData(XHEATED, XHeatedto15degreesCelsiusTxt);
        InsertData(XFROZEN, Xminus8degreesCelsiusTxt);
        InsertData(XCOLD, X2degreesCelsiusTxt);
        InsertData(XDRY, XNottoexceed60humidityTxt);
        InsertData(XNONSTATIC, XAntistaticareaTxt);
    end;

    var
        XHEATED: Label 'HEATED';
        XHeatedto15degreesCelsiusTxt: Label 'Heated to 15 degrees Celsius';
        XFROZEN: Label 'FROZEN';
        Xminus8degreesCelsiusTxt: Label '- 8 degrees Celsius';
        XCOLD: Label 'COLD';
        X2degreesCelsiusTxt: Label '2 degrees Celsius';
        XDRY: Label 'DRY';
        XNottoexceed60humidityTxt: Label 'Not to exceed 60 % humidity';
        XNONSTATIC: Label 'NONSTATIC';
        XAntistaticareaTxt: Label 'Anti static area';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    var
        "Warehouse Class": Record "Warehouse Class";
    begin
        "Warehouse Class".Validate(Code, Code);
        "Warehouse Class".Validate(Description, Description);
        "Warehouse Class".Insert();
    end;
}

