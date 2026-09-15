codeunit 101200 "Create Work Type"
{

    trigger OnRun()
    begin
        InsertData(XMILES, XMILES_DESCRIPTION, XMILES);
    end;

    var
        WorkType: Record "Work Type";
        XMILES: Label 'MILES';
        XMILES_DESCRIPTION: Label 'MILES';

    procedure InsertData("Code": Code[10]; Description: Text[30]; UnitOfMeasure: Code[20])
    begin
        WorkType.Init();
        WorkType.Validate(Code, Code);
        WorkType.Validate(Description, Description);
        WorkType.Validate("Unit of Measure Code", UnitOfMeasure);
        WorkType.Insert();
    end;
}

