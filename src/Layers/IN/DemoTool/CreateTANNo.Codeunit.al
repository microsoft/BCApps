codeunit 101016 "Create TAN No"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();

        InsertData('BLU0897580', XBlueLocationLbl);
        InsertData('REDN03830B', XRedLocationLbl);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XBlueLocationLbl: Label 'BLUE Location';
        XRedLocationLbl: Label 'Red Location';

    procedure InsertMiniAppData()
    begin
        AddTANNoForMini();
    end;

    local procedure AddTANNoForMini()
    begin
        DemoDataSetup.Get();
        InsertData('BLU0897580', XBlueLocationLbl);
        InsertData('REDN03830B', XRedLocationLbl);
    end;

    procedure InsertData(Code: Code[20]; Description: Text[50])
    var
        TANNos: Record "TAN Nos.";
    begin
        TANNos.Init();
        TANNos.Validate("Code", Code);
        TANNos.Validate(Description, Description);
        TANNos.Insert();
    end;
}
