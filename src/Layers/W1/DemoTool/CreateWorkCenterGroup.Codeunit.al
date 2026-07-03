codeunit 119014 "Create Work Center Group"
{

    trigger OnRun()
    begin
        InsertData('1', XInventorydepartment);
        InsertData('2', XProductiondepartment);
    end;

    var
        XInventorydepartment: Label 'Inventory department';
        XProductiondepartment: Label 'Production department';

    procedure InsertData("Code": Code[10]; Name: Text[30])
    var
        WorkCenterGroup: Record "Work Center Group";
    begin
        WorkCenterGroup.Validate(Code, Code);
        WorkCenterGroup.Validate(Name, Name);
        WorkCenterGroup.Insert();
    end;
}

