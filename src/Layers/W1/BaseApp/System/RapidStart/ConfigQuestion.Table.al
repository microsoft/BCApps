namespace System.IO;

using System.Reflection;

table 8612 "Config. Question"
{
    Caption = 'Config. Question';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Questionnaire Code"; Code[10])
        {
            Caption = 'Questionnaire Code';
            Editable = false;
            TableRelation = "Config. Questionnaire".Code;
        }
        field(2; "Question Area Code"; Code[10])
        {
            Caption = 'Question Area Code';
            Editable = false;
            TableRelation = "Config. Question Area".Code where("Questionnaire Code" = field("Questionnaire Code"));
        }
        field(3; "No."; Integer)
        {
            Caption = 'No.';
            MinValue = 1;
        }
        field(4; Question; Text[250])
        {
            Caption = 'Question';
        }
        field(5; "Answer Option"; Text[250])
        {
            Caption = 'Answer Option';
            Editable = false;
        }
        field(6; Answer; Text[250])
        {
            Caption = 'Answer';

            trigger OnLookup()
            begin
                AnswerLookup();
            end;

            trigger OnValidate()
            var
                TempConfigPackageField: Record "Config. Package Field" temporary;
                ConfigValidateMgt: Codeunit "Config. Validate Management";
                ConfigPackageManagement: Codeunit "Config. Package Management";
                RecRef: RecordRef;
                FieldRef: FieldRef;
                ValidationError: Text;
            begin
                if ("Field ID" <> 0) and (Answer <> '') then begin
                    RecRef.Open("Table ID", true);
                    FieldRef := RecRef.Field("Field ID");
                    ValidationError := ConfigValidateMgt.EvaluateValue(FieldRef, Answer, false);
                    if ValidationError <> '' then
                        Error(ValidationError);

                    Answer := Format(FieldRef.Value);

                    ConfigPackageManagement.GetFieldsOrder(RecRef, '', TempConfigPackageField);
                    ValidationError := ConfigPackageManagement.ValidateFieldRefRelationAgainstCompanyData(FieldRef, TempConfigPackageField);
                    if ValidationError <> '' then
                        Error(ValidationError);
                end;
            end;
        }
        field(7; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(8; "Field ID"; Integer)
        {
            Caption = 'Field ID';

            trigger OnLookup()
            begin
                FieldLookup();
            end;
        }
        field(9; Reference; Text[250])
        {
            Caption = 'Reference';
            ExtendedDatatype = URL;
        }
        field(10; "Question Origin"; Text[30])
        {
            Caption = 'Question Origin';
        }
        field(11; "Field Name"; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Table ID"),
                                                        "No." = field("Field ID")));
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;

            trigger OnLookup()
            begin
                FieldLookup();
            end;
        }
        field(12; "Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Field ID")));
            Caption = 'Field Caption';
            Editable = false;
            FieldClass = FlowField;

            trigger OnLookup()
            begin
                FieldLookup();
            end;
        }
    }

    keys
    {
        key(Key1; "Questionnaire Code", "Question Area Code", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Questionnaire Code", "Question Area Code", "Field ID")
        {
        }
        key(Key3; "Table ID", "Field ID")
        {
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0470
        QuestionAlreadyExistsErr: Label 'Question no. %1 already exists for the field %2.';
#pragma warning restore AA0470

    procedure FieldLookup()
    var
        ConfigQuestion1: Record "Config. Question";
        ConfigQuestionArea: Record "Config. Question Area";
        "Field": Record "Field";
        ConfigQuestionnaireMgt: Codeunit "Questionnaire Management";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        FieldSelection: Codeunit "Field Selection";
    begin
        ConfigQuestionArea.Get("Questionnaire Code", "Question Area Code");

        if ConfigQuestionArea."Table ID" = 0 then
            exit;

        ConfigPackageMgt.SetFieldFilter(Field, ConfigQuestionArea."Table ID", 0);
        if FieldSelection.Open(Field) then begin
            "Table ID" := Field.TableNo;
            "Field ID" := Field."No.";

            ConfigQuestion1.SetRange("Questionnaire Code", "Questionnaire Code");
            ConfigQuestion1.SetRange("Question Area Code", "Question Area Code");
            ConfigQuestion1.SetRange("Table ID", "Table ID");
            ConfigQuestion1.SetRange("Field ID", "Field ID");
            if ConfigQuestion1.FindFirst() then begin
                "Field ID" := 0;
                ConfigQuestion1.CalcFields("Field Caption");
                Error(QuestionAlreadyExistsErr, ConfigQuestion1."No.", ConfigQuestion1."Field Caption");
            end;

            if Question = '' then
                Question := Field."Field Caption" + '?';
            "Answer Option" := ConfigQuestionnaireMgt.BuildAnswerOption("Table ID", "Field ID");
            CalcFields("Field Name", "Field Caption");
        end;
    end;

    local procedure AnswerLookup()
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ConfigPackageDataPage: Page "Config. Package Data";
        RelatedTableID: Integer;
        RelatedFieldID: Integer;
    begin
        ConfigValidateMgt.GetRelationInfoByIDs("Table ID", "Field ID", RelatedTableID, RelatedFieldID);
        if RelatedTableID <> 0 then begin
            ConfigPackageData.SetRange("Table ID", RelatedTableID);
            ConfigPackageData.SetRange("Field ID", RelatedFieldID);

            Clear(ConfigPackageDataPage);
            ConfigPackageDataPage.SetTableView(ConfigPackageData);
            ConfigPackageDataPage.LookupMode := true;
            if ConfigPackageDataPage.RunModal() = ACTION::LookupOK then begin
                ConfigPackageDataPage.GetRecord(ConfigPackageData);
                Answer := CopyStr(ConfigPackageData.Value, 1, MaxStrLen(Answer));
            end;
        end;
    end;

    procedure LookupValue(): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        if "Table ID" > 0 then begin
            RecRef.Open("Table ID");
            RecRef.FindFirst();
            FieldRef := RecRef.Field("Field ID");
            exit(Format(FieldRef.Value));
        end;
    end;
}

