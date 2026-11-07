codeunit 118837 "Create Physical Inventory"
{

    trigger OnRun()
    begin
        InsertData(XFAST, XFastmoversorHighvalue, 6);
        InsertData(XNormal, XNormalsaleormediumvalue, 2);
        InsertData(XSLOW, XSlowmoversorlowvalue, 1);
    end;

    var
        XFAST: Label 'FAST';
        XFastmoversorHighvalue: Label 'Fast movers or High value';
        XNormal: Label 'Normal';
        XNormalsaleormediumvalue: Label 'Normal sale or medium value';
        XSLOW: Label 'SLOW';
        XSlowmoversorlowvalue: Label 'Slow movers or low value';

    procedure InsertData("Code": Code[10]; Description: Text[30]; CountFrequency: Integer)
    var
        "Physical Inventory Cycle": Record "Phys. Invt. Counting Period";
    begin
        "Physical Inventory Cycle".Validate(Code, Code);
        "Physical Inventory Cycle".Validate(Description, Description);
        "Physical Inventory Cycle".Validate("Count Frequency per Year", CountFrequency);
        "Physical Inventory Cycle".Insert();
    end;
}

