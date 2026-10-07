codeunit 101818 "Create FA Insurance Type"
{

    trigger OnRun()
    begin
        InsertData(XCAR, XCarlc);
        InsertData(XMACHINERY, XMachineryOtherEquipment);
        InsertData(XTHEFT, XMachineryOtherEquipment);
        InsertData(XFIRE, XMachineryOtherEquipment);
    end;

    var
        "Insurance Type": Record "Insurance Type";
        XCAR: Label 'CAR';
        XCarlc: Label 'Car';
        XMACHINERY: Label 'MACHINERY';
        XMachineryOtherEquipment: Label 'Machinery/Other Equipment';
        XTHEFT: Label 'THEFT';
        XFIRE: Label 'FIRE';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        "Insurance Type".Init();
        "Insurance Type".Validate(Code, Code);
        "Insurance Type".Validate(Description, Description);
        "Insurance Type".Insert();
    end;
}

