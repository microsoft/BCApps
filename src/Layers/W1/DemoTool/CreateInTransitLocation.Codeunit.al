codeunit 118010 "Create In-Transit Location"
{

    trigger OnRun()
    begin
        InsertData(XOWNLOG, XOwnLogistics, true);
        InsertData(XOUTLOG, XOutsourcedLogistics, true);
    end;

    var
        Location: Record Location;
        XOWNLOG: Label 'OWN LOG.';
        XOwnLogistics: Label 'Own Logistics';
        XOUTLOG: Label 'OUT. LOG.';
        XOutsourcedLogistics: Label 'Outsourced Logistics';

    local procedure InsertData("Code": Code[10]; Name: Text[50]; InTransit: Boolean)
    begin
        if not Location.Get(Code) then begin
            Location.Init();
            Location.Validate(Code, Code);
            Location.Validate(Name, Name);
            Location.Validate("Use As In-Transit", InTransit);
            Location.Insert();
        end;
    end;
}

