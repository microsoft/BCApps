namespace System.IO;

table 8610 "Config. Questionnaire"
{
    Caption = 'Config. Questionnaire';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
    begin
        ConfigQuestionArea.Reset();
        ConfigQuestionArea.SetRange("Questionnaire Code", Code);
        ConfigQuestionArea.DeleteAll();
        ConfigQuestion.Reset();
        ConfigQuestion.SetRange("Questionnaire Code", Code);
        ConfigQuestion.DeleteAll();
    end;

    trigger OnRename()
    begin
        Error(CannotRenameQuestionnaireErr);
    end;

    var
        CannotRenameQuestionnaireErr: Label 'You cannot rename a configuration questionnaire.';
}

