codeunit 117016 "Create Fault Area"
{

    trigger OnRun()
    begin
        InsertData('1', XGeneral);
        InsertData('2', XCommunication);
        InsertData('3', XPicture);
        InsertData('4', XColor);
        InsertData('5', XSound);
        InsertData('6', XMechanics);
        InsertData('7', XDataspaceprocessing);
        InsertData('8', XPrinting);
        InsertData('A', XWashingslashdrying);
        InsertData('B', XCoolingslashheating);
        InsertData('C', XCookingcommaPool);
        InsertData('D', XPoolslashshower);
    end;

    var
        XGeneral: Label 'General';
        XCommunication: Label 'Communication';
        XPicture: Label 'Picture';
        XColor: Label 'Color';
        XSound: Label 'Sound';
        XMechanics: Label 'Mechanics';
        XDataspaceprocessing: Label 'Data processing';
        XPrinting: Label 'Printing';
        XWashingslashdrying: Label 'Washing / drying';
        XCoolingslashheating: Label 'Cooling / heating';
        XCookingcommaPool: Label 'Cooking,Pool';
        XPoolslashshower: Label 'Pool / shower';

    procedure InsertData("Code": Text[250]; Description: Text[250])
    var
        FaultArea: Record "Fault Area";
    begin
        FaultArea.Init();
        FaultArea.Validate(Code, Code);
        FaultArea.Validate(Description, Description);
        FaultArea.Insert(true);
    end;
}

