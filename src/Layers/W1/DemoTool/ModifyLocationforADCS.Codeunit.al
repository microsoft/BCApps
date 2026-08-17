codeunit 118861 "Modify Location for ADCS"
{

    trigger OnRun()
    begin
        InsertData(Xwhite);
    end;

    var
        Location: Record Location;
        Xwhite: Label 'white';

    procedure InsertData(LocationCode: Code[20])
    begin
        Location.Init();
        if Location.Get(LocationCode) then;
        Location."Use ADCS" := true;
        Location.Modify();
    end;
}

