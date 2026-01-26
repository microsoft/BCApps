codeunit 101259 "Create Transport Method"
{

    trigger OnRun()
    begin
        // InsertData('1',XSea);
        // InsertData('2',XRail);
        // InsertData('3',XRoad);
        // InsertData('4',XAir);
        // InsertData('5',XPost);
        // InsertData('7',XFixedinstallations);
        // InsertData('9',XOwnpropulsion);
        InsertData('1', XSea, true);
        InsertData('2', XRail, false);
        InsertData('3', XRoad, false);
        InsertData('4', XAir, true);
        InsertData('5', XPost, false);
        InsertData('7', XFixedinstallations, false);
        InsertData('9', XOwnpropulsion, false);
    end;

    var
        "Transport Method": Record "Transport Method";
        XSea: Label 'Sea';
        XRail: Label 'Rail';
        XRoad: Label 'Road';
        XAir: Label 'Air';
        XPost: Label 'Post';
        XFixedinstallations: Label 'Fixed installations';
        XOwnpropulsion: Label 'Own propulsion';

    procedure InsertData("Code": Code[10]; Description: Text[50]; "Port/Airport": Boolean)
    begin
        "Transport Method".Init();
        "Transport Method".Validate(Code, Code);
        "Transport Method".Validate(Description, Description);
        "Transport Method".Validate("Port/Airport", "Port/Airport");
        "Transport Method".Insert();
    end;
}

