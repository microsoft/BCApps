codeunit 101618 "Create Human Resources Setup"
{

    trigger OnRun()
    begin
        "Human Resouces Setup".Get();
        "Create No. Series".InitBaseSeries("Human Resouces Setup"."Employee Nos.", XEMP, XEmployee, XE10, XE9990, '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Human Resouces Setup".Modify();
    end;

    var
        "Human Resouces Setup": Record "Human Resources Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XEMP: Label 'EMP';
        XEmployee: Label 'Employee';
        XE10: Label 'E10';
        XE9990: Label 'E9990';
}

