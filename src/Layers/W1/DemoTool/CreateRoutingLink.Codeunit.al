codeunit 119019 "Create Routing Link"
{

    trigger OnRun()
    begin
        InsertData('100', XAssembling);
        InsertData('200', XCNCAxle);
        InsertData('300', XInspection);
    end;

    var
        XAssembling: Label 'Assembling';
        XCNCAxle: Label 'CNC/Axle';
        XInspection: Label 'Inspection';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    var
        RoutingLink: Record "Routing Link";
    begin
        RoutingLink.Validate(Code, Code);
        RoutingLink.Validate(Description, Description);
        RoutingLink.Insert();
    end;
}

