codeunit 117560 "Add Job Responsibility"
{

    trigger OnRun()
    begin
        InsertRec(XSERVICE, XServiceResponsible);
    end;

    var
        XSERVICE: Label 'SERVICE';
        XServiceResponsible: Label 'Service Responsible';

    procedure InsertRec(Fld1: Text[10]; Fld2: Text[30])
    var
        NewRec: Record "Job Responsibility";
    begin
        NewRec.Init();
        Evaluate(NewRec.Code, Fld1);
        Evaluate(NewRec.Description, Fld2);
        NewRec.Insert();
    end;
}

