codeunit 101042 "Create Rounding Method"
{

    trigger OnRun()
    begin
        InsertData(XWHOLE, 1);
        InsertData(XTEN, 10);
        InsertData(XHUNDRED, 100);
        InsertData(XTHOUSAND, 1000);
    end;

    var
        "Rounding Method": Record "Rounding Method";
        XWHOLE: Label 'WHOLE';
        XTEN: Label 'TEN';
        XHUNDRED: Label 'HUNDRED';
        XTHOUSAND: Label 'THOUSAND';

    procedure InsertData(MethodName: Code[10]; RoundingPrecision: Decimal)
    begin
        "Rounding Method".Init();
        "Rounding Method".Validate(Code, MethodName);
        "Rounding Method".Validate(Precision, RoundingPrecision);
        "Rounding Method".Insert();
    end;
}

