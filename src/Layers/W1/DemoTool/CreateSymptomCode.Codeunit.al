codeunit 117017 "Create Symptom Code"
{

    trigger OnRun()
    begin
        InsertData('1', XNospacefunction);
        InsertData('2', XLevel);
        InsertData('3', XQuality);
        InsertData('4', XNoise);
        InsertData('5', XUnstable);
        InsertData('6', XRecordingandphysical);
        InsertData('7', XSpecialspacefunctions);
        InsertData('8', XOtherspaceconditions);
        InsertData('9', XSpecialspacecategories);
    end;

    var
        XNospacefunction: Label 'No function';
        XLevel: Label 'Level';
        XQuality: Label 'Quality';
        XNoise: Label 'Noise';
        XUnstable: Label 'Unstable';
        XRecordingandphysical: Label 'Recording and physical';
        XSpecialspacefunctions: Label 'Special functions';
        XOtherspaceconditions: Label 'Other conditions';
        XSpecialspacecategories: Label 'Special categories';

    procedure InsertData("Code": Text[250]; Description: Text[250])
    var
        SymptomCode: Record "Symptom Code";
    begin
        SymptomCode.Init();
        SymptomCode.Validate(Code, Code);
        SymptomCode.Validate(Description, Description);
        SymptomCode.Insert(true);
    end;
}

