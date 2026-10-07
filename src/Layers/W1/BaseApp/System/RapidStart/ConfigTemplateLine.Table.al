namespace System.IO;

using System.Reflection;

table 8619 "Config. Template Line"
{
    Caption = 'Config. Template Line';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Template Code"; Code[10])
        {
            Caption = 'Data Template Code';
            Editable = false;
            TableRelation = "Config. Template Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; Type; Enum "Config. Template Line Type")
        {
            Caption = 'Type';
            InitValue = "Field";

            trigger OnValidate()
            begin
                case Type of
                    Type::Field:
                        Clear("Template Code");
                    Type::Template:
                        begin
                            Clear("Field Name");
                            Clear("Field ID");
                        end;
                end;
            end;
        }
        field(4; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = if (Type = const(Field)) Field."No." where(TableNo = field("Table ID"),
                                                                      Class = const(Normal));
        }
        field(5; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
            Editable = false;
            FieldClass = Normal;

            trigger OnLookup()
            begin
                SelectFieldName();
            end;

            trigger OnValidate()
            var
                ConfigTemplateLine: Record "Config. Template Line";
                ConfigTemplateMgt: Codeunit "Config. Template Management";
            begin
                ConfigTemplateLine.SetRange("Data Template Code", "Data Template Code");
                ConfigTemplateLine.SetRange("Field Name", "Field Name");
                if not ConfigTemplateLine.IsEmpty() then
                    Error(TemplateFieldExistsErr, "Field Name");

                ConfigTemplateMgt.TestHierarchy(Rec);
            end;
        }
        field(6; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(7; "Table Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = filter(Table),
                                                                        "Object ID" = field("Table ID")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Template Code"; Code[10])
        {
            Caption = 'Template Code';
            TableRelation = "Config. Template Header";

            trigger OnLookup()
            var
                ConfigTemplateHeader: Record "Config. Template Header";
                ConfigTemplateList: Page "Config. Template List";
            begin
                if Type = Type::Field then
                    exit;

                ConfigTemplateList.LookupMode := true;
                ConfigTemplateList.Editable := false;
                if ConfigTemplateList.RunModal() = ACTION::LookupOK then begin
                    ConfigTemplateList.GetRecord(ConfigTemplateHeader);
                    if ConfigTemplateHeader.Code = "Data Template Code" then
                        Error(TemplateRelationErr);
                    CalcFields("Template Description");
                    Validate("Template Code", ConfigTemplateHeader.Code);
                end;
            end;

            trigger OnValidate()
            var
                ConfigTemplateLine: Record "Config. Template Line";
                ConfigTemplateMgt: Codeunit "Config. Template Management";
            begin
                if Type = Type::Field then
                    Error(TemplateFieldLineErr);

                if "Template Code" = "Data Template Code" then
                    Error(TemplateRelationErr);

                ConfigTemplateMgt.TestHierarchy(Rec);

                ConfigTemplateLine.SetRange("Data Template Code", "Data Template Code");
                ConfigTemplateLine.SetRange("Template Code", "Template Code");
                if not ConfigTemplateLine.IsEmpty() then
                    Error(TemplateHierarchyErr, "Template Code");
            end;
        }
        field(9; "Template Description"; Text[100])
        {
            CalcFormula = lookup("Config. Template Header".Description where(Code = field("Data Template Code")));
            Caption = 'Template Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; Mandatory; Boolean)
        {
            Caption = 'Mandatory';

            trigger OnValidate()
            begin
                if Mandatory and ("Default Value" = '') then
                    Error(EmptyDefaultValueErr);
            end;
        }
        field(11; Reference; Text[250])
        {
            Caption = 'Reference';
            ExtendedDatatype = URL;
        }
        field(12; "Default Value"; Text[2048])
        {
            Caption = 'Default Value';

            trigger OnLookup()
            var
                FieldValue: Text;
            begin
                if LookupFieldValue(FieldValue) then
                    Validate("Default Value", CopyStr(FieldValue, 1, MaxStrLen("Default Value")));
            end;

            trigger OnValidate()
            var
                ConfigValidateMgt: Codeunit "Config. Validate Management";
                RecRef: RecordRef;
                FieldRef: FieldRef;
                ValidationError: Text;
            begin
                if Mandatory and ("Default Value" = '') then
                    Error(EmptyDefaultValueErr);
                if ("Field ID" <> 0) and ("Default Value" <> '') then begin
                    RecRef.Open("Table ID", true);
                    FieldRef := RecRef.Field("Field ID");
                    ValidationError := ConfigValidateMgt.EvaluateValue(FieldRef, "Default Value", false);
                    if ValidationError <> '' then
                        Error(ValidationError);

                    "Default Value" := Format(FieldRef.Value);

                    if not "Skip Relation Check" then begin
                        ConfigValidateMgt.TransferRecordDefaultValues("Data Template Code", RecRef, "Field ID", "Default Value");
                        ValidationError := ConfigValidateMgt.ValidateFieldRefRelationAgainstCompanyData(FieldRef);

                        if ValidationError <> '' then
                            Error(ValidationError);
                    end;

                    if GlobalLanguage <> "Language ID" then
                        Validate("Language ID", GlobalLanguage);
                end
            end;
        }
        field(13; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = filter(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Field ID")));
            Caption = 'Field Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Skip Relation Check"; Boolean)
        {
            Caption = 'Skip Relation Check';
        }
        field(16; "Language ID"; Integer)
        {
            Caption = 'Language ID';
            InitValue = 0;
        }
    }

    keys
    {
        key(Key1; "Data Template Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Data Template Code", Type)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        if ConfigTemplateHeader.Get("Data Template Code") then begin
            "Table ID" := ConfigTemplateHeader."Table ID";
            if "Language ID" = 0 then
                "Language ID" := GlobalLanguage;
        end;
    end;

    var
        TemplateRelationErr: Label 'A template cannot relate to itself. Specify a different template.';
        TemplateHierarchyErr: Label 'The template %1 is already in this hierarchy.', Comment = '%1 - Field Value';
        TemplateFieldExistsErr: Label 'Field %1 is already in the template.', Comment = '%1 - Field Name';
        TemplateFieldLineErr: Label 'The template line cannot be edited if type is Field.';
        EmptyDefaultValueErr: Label 'The Default Value field must be filled in if the Mandatory check box is selected.';

    procedure SelectFieldName()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        "Field": Record "Field";
        FieldSelection: Codeunit "Field Selection";
    begin
        if Type = Type::Template then
            exit;

        ConfigTemplateHeader.Get("Data Template Code");

        if ConfigTemplateHeader."Table ID" = 0 then
            exit;

        SetFieldFilter(Field, ConfigTemplateHeader."Table ID", 0);
        if FieldSelection.Open(Field) then begin
            "Table ID" := Field.TableNo;
            Validate("Field ID", Field."No.");
            Validate("Field Name", Field.FieldName);
        end;
    end;

    procedure GetLine(var ConfigTemplateLine: Record "Config. Template Line"; DataTemplateCode: Code[10]; FieldID: Integer): Boolean
    begin
        ConfigTemplateLine.SetRange("Data Template Code", DataTemplateCode);
        ConfigTemplateLine.SetRange("Field ID", FieldID);
        if not ConfigTemplateLine.FindFirst() then
            exit(false);
        exit(true)
    end;

    local procedure SetFieldFilter(var "Field": Record "Field"; TableID: Integer; FieldID: Integer)
    begin
        Field.Reset();
        if TableID > 0 then
            Field.SetRange(TableNo, TableID);
        if FieldID > 0 then
            Field.SetRange("No.", FieldID);
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(Enabled, true);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
    end;

    local procedure LookupFieldValue(var FieldValue: Text): Boolean
    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        if (Type <> Type::Field) or ("Field ID" = 0) then
            exit(false);

        exit(ConfigTemplateManagement.LookupFieldValueFromConfigTemplateLine(Rec, FieldValue));
    end;
}
