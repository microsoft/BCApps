codeunit 101620 "Create Human Resources Uom"
{

    trigger OnRun()
    begin
        InsertData(XHOUR, 1 / 8, false);
        InsertData(XDAY, 1, true);
    end;

    var
        HRUoM: Record "Human Resource Unit of Measure";
        HRSetUp: Record "Human Resources Setup";
        XHOUR: Label 'HOUR';
        XDAY: Label 'DAY';

    procedure InsertData(CodeParam: Code[10]; QtyParam: Decimal; BaseUoM: Boolean)
    begin
        HRUoM.Init();
        HRUoM.Code := CodeParam;
        HRUoM."Qty. per Unit of Measure" := QtyParam;
        HRUoM.Insert();
        if BaseUoM then begin
            HRSetUp.Get();
            HRSetUp.Validate("Base Unit of Measure", HRUoM.Code);
            HRSetUp.Modify();
        end;
    end;
}

