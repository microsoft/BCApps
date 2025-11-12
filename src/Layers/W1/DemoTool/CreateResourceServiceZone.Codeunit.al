codeunit 117059 "Create Resource Service Zone"
{

    trigger OnRun()
    begin
        InsertData(XKatherine, XM, 0D, '');
        InsertData(XKatherine, XN, 0D, '');
        InsertData(XKatherine, XX, 0D, '');
        InsertData(XLina, XM, 0D, '');
        InsertData(XLina, XSE, 0D, '');
        InsertData(XLina, XW, 19030102D, '');
        InsertData(XMARTY, XSE, 0D, '');
        InsertData(XMARTY, XW, 19030102D, '');
        InsertData(XTerry, XM, 0D, '');
        InsertData(XTerry, XN, 0D, '');
    end;

    var
        XKatherine: Label 'Katherine';
        XM: Label 'M';
        XLina: Label 'Lina';
        XN: Label 'N';
        XSE: Label 'SE';
        XX: Label 'X';
        XW: Label 'W';
        XMarty: Label 'Marty';
        XTerry: Label 'Terry';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("Resource No.": Text[250]; "Service Zone Code": Text[250]; "Starting Date": Date; Description: Text[250])
    var
        ResourceServiceZone: Record "Resource Service Zone";
    begin
        ResourceServiceZone.Init();
        ResourceServiceZone.Validate("Resource No.", "Resource No.");
        ResourceServiceZone.Validate("Service Zone Code", "Service Zone Code");
        ResourceServiceZone.Validate("Starting Date", MakeAdjustments.AdjustDate("Starting Date"));
        ResourceServiceZone.Validate(Description, Description);
        ResourceServiceZone.Insert(true);
    end;
}

