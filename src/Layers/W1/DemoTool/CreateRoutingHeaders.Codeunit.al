codeunit 119026 "Create Routing Headers"
{

    trigger OnRun()
    begin
        InsertData('1000', '', XBicycle, 0, 19020101D);
        InsertData('1100', '', XFrontWheel, 0, 19020101D);
        InsertData('1150', '', XHub, 1, 19020101D);
        InsertData('1200', '', XBackWheel, 0, 19020101D);
    end;

    var
        CA: Codeunit "Make Adjustments";
        XBicycle: Label 'Bicycle';
        XFrontWheel: Label 'Front Wheel';
        XHub: Label 'Hub';
        XBackWheel: Label 'Back Wheel';

    procedure InsertData(RoutingNo: Code[20]; RtngVersionCode: Code[10]; Description: Text[30]; Type: Option Serial,Parallel; StartingDate: Date)
    var
        Routing: Record "Routing Header";
        RtngVersion: Record "Routing Version";
    begin
        if not Routing.Get(RoutingNo) then begin
            Routing.Validate("No.", RoutingNo);
            Routing.Insert();
            Routing.Validate(Description, Description);
            Routing.Validate(Type, Type);
            Routing.Modify();
        end;
        if RtngVersionCode <> '' then begin
            RtngVersion.Validate("Routing No.", RoutingNo);
            RtngVersion.Validate("Version Code", RtngVersionCode);
            RtngVersion.Insert();
            RtngVersion.Validate(Description, Description);
            RtngVersion.Validate("Starting Date", CA.AdjustDate(StartingDate));
            RtngVersion.Modify();
        end;
    end;
}

