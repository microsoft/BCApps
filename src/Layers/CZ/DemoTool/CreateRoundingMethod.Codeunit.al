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
        XCROWNS: Label 'CROWNS';

    procedure InsertData(MethodName: Code[10]; RoundingPrecision: Decimal)
    begin
        "Rounding Method".Init();
        "Rounding Method".Validate(Code, MethodName);
        "Rounding Method".Validate(Precision, RoundingPrecision);
        // NAVCZ
        if MethodName = XCROWNS then
            "Rounding Method".Validate(Type, "Rounding Method".Type::Up);
        // NAVCZ
        "Rounding Method".Insert();
    end;

    procedure InsertMiniAppData()
    begin
        // NAVCZ
        InsertData(XCROWNS, 1);
    end;

    procedure GetRoundingMethod(RoundingMethod: Text): Code[10]
    begin
        case UpperCase(RoundingMethod) of
            'XWHOLE':
                exit(XWHOLE);
            'XTEN':
                exit(XTEN);
            'XHUNDRED':
                exit(XHUNDRED);
            'XTHOUSAND':
                exit(XTHOUSAND);
            'XCROWNS':
                exit(XCROWNS);
            else
                Error('Unknown Rounding Method %1.', RoundingMethod);
        end
    end;
}
