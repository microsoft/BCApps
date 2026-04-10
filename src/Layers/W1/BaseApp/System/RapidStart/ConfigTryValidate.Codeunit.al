namespace System.IO;

codeunit 8613 "Config. Try Validate"
{

    trigger OnRun()
    begin
        FieldRefToValidate.Validate(Value);
    end;

    var
        FieldRefToValidate: FieldRef;
        Value: Variant;

    procedure SetValidateParameters(var SourceFieldRef: FieldRef; SourceValue: Variant)
    begin
        FieldRefToValidate := SourceFieldRef;
        Value := SourceValue;
    end;
}

