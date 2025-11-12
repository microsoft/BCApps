namespace System.IO;

using System.Reflection;

table 8616 "Config. Package Field"
{
    Caption = 'Config. Package Field';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            NotBlank = true;
            TableRelation = "Config. Package";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(3; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            NotBlank = true;
            TableRelation = Field."No." where(TableNo = field("Table ID"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateFieldIDTableRelation();
            end;
        }
        field(4; "Field Name"; Text[30])
        {
            Caption = 'Field Name';

            trigger OnValidate()
            begin
                "XML Field Name" := GetUniqueElementName("Field Name");
            end;
        }
        field(5; "Field Caption"; Text[250])
        {
            Caption = 'Field Caption';
        }
        field(6; "Validate Field"; Boolean)
        {
            Caption = 'Validate Field';

            trigger OnValidate()
            var
                ShouldRunCheck: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateValidateField(Rec, IsHandled);
                if IsHandled then
                    exit;

                ShouldRunCheck := not Dimension;
                OnValidateFieldOnValidateOnAfterCalcShouldRunCheck(Rec, ShouldRunCheck);
                if ShouldRunCheck then begin
                    if "Validate Field" then
                        ThrowErrorIfFieldRemoved();
                    UpdateFieldErrors();
                end;
            end;
        }
        field(7; "Include Field"; Boolean)
        {
            Caption = 'Include Field';

            trigger OnValidate()
            var
                ShouldRunCheck: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateIncludeField(Rec, IsHandled);
                if IsHandled then
                    exit;
                ShouldRunCheck := not Dimension;
                OnIncludeFieldOnValidateOnAfterCalcShouldRunCheck(Rec, ShouldRunCheck);
                if ShouldRunCheck then begin
                    if xRec."Include Field" and not "Include Field" and "Primary Key" then
                        Error(PrimaryKeyRequiredErr, "Field Caption");
                    if "Include Field" then
                        ThrowErrorIfFieldRemoved();
                    "Validate Field" := "Include Field";
                    UpdateFieldErrors();
                end;
            end;
        }
        field(8; "Localize Field"; Boolean)
        {
            Caption = 'Localize Field';
        }
        field(9; "Relation Table ID"; Integer)
        {
            Caption = 'Relation Table ID';
            Editable = false;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(10; "Relation Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table),
                                                                        "Object ID" = field("Relation Table ID")));
            Caption = 'Relation Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Dimension; Boolean)
        {
            Caption = 'Dimension';
            Editable = false;
        }
        field(12; "Primary Key"; Boolean)
        {
            Caption = 'Primary Key';
            Editable = false;
        }
        field(13; "Processing Order"; Integer)
        {
            Caption = 'Processing Order';
        }
        field(14; "Create Missing Codes"; Boolean)
        {
            Caption = 'Create Missing Codes';

            trigger OnValidate()
            begin
                if "Create Missing Codes" then
                    TestField("Relation Table ID");
            end;
        }
        field(15; "Mapping Exists"; Boolean)
        {
            CalcFormula = exist("Config. Field Map" where("Package Code" = field("Package Code"),
                                                               "Table ID" = field("Table ID"),
                                                               "Field ID" = field("Field ID")));
            Caption = 'Mapping Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; AutoIncrement; Boolean)
        {
            Caption = 'AutoIncrement';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("Primary Key", false);
                TestFieldIsInteger();
            end;
        }
        field(20; "XML Field Name"; Text[30])
        {
            Caption = 'XML Field Name';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Package Code", "Table ID", "Field ID")
        {
            Clustered = true;
        }
        key(Key2; "Package Code", "Table ID", "Include Field")
        {
        }
        key(Key3; "Package Code", "Table ID", "Validate Field")
        {
        }
        key(Key4; "Package Code", "Table ID", "Processing Order")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteConfigFieldMap();
    end;

    var
#pragma warning disable AA0470
        PrimaryKeyRequiredErr: Label '%1 is part of the primary key and must be included.';
        FieldValueNotExistErr: Label '%1 value ''%2'' does not exist.';
#pragma warning restore AA0470
        UpdateValErrsTxt: Label 'Updating validation errors';
        MustBeIntegersErr: Label 'must be Integer or BigInteger';

    local procedure UpdateFieldErrors()
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ErrorText: Text[250];
        ShouldRunCheck: Boolean;
    begin
        ShouldRunCheck := not Dimension;
        OnUpdateFieldErrorsOnAfterCalcShouldRunCheck(Rec, ShouldRunCheck);
        if ShouldRunCheck then begin
            if "Include Field" then begin
                RecRef.Open("Table ID", true);
                FieldRef := RecRef.Field("Field ID");
            end;
            ConfigPackageData.SetRange("Package Code", "Package Code");
            ConfigPackageData.SetRange("Table ID", "Table ID");
            ConfigPackageData.SetRange("Field ID", "Field ID");
            if ConfigPackageData.FindSet() then begin
                ConfigProgressBar.Init(ConfigPackageData.Count, 1, UpdateValErrsTxt);
                repeat
                    ConfigProgressBar.Update(ConfigPackageData.Value);
                    ConfigPackageRecord.Get(
                      ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."No.");
                    ConfigPackageMgt.CleanFieldError(ConfigPackageData);
                    if "Include Field" then begin
                        ErrorText := CopyStr(ConfigValidateMgt.EvaluateValue(FieldRef, ConfigPackageData.Value, false), 1, MaxStrLen(ErrorText));
                        ConfigPackageMgt.FieldError(ConfigPackageData, ErrorText, 0);
                        if "Validate Field" then begin
                            Clear(TempConfigPackageTable);
                            ConfigPackageField.Init();
                            ConfigPackageField.Reset();
                            ConfigPackageField.SetRange("Package Code", "Package Code");
                            ConfigPackageField.SetRange("Table ID", "Table ID");
                            ConfigPackageField.SetRange("Field ID", "Field ID");
                            if not ConfigPackageMgt.ValidateFieldRelationInRecord(
                                 ConfigPackageField, TempConfigPackageTable, ConfigPackageRecord, RecRef)
                            then
                                ConfigPackageMgt.FieldError(ConfigPackageData, StrSubstNo(FieldValueNotExistErr, FieldRef.Caption, ConfigPackageData.Value), 0);
                        end;
                    end;
                until ConfigPackageData.Next() = 0;
                ConfigProgressBar.Close();
            end;
        end;
    end;

    local procedure DeleteConfigFieldMap()
    var
        ConfigFieldMap: Record "Config. Field Map";
    begin
        ConfigFieldMap.SetRange("Package Code", "Package Code");
        ConfigFieldMap.SetRange("Table ID", "Table ID");
        ConfigFieldMap.SetRange("Field ID", "Field ID");
        ConfigFieldMap.DeleteAll();
    end;

    procedure GetRelationTablesID() Result: Text
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        TableRelationsMetadata.SetRange("Table ID", "Table ID");
        TableRelationsMetadata.SetRange("Field No.", "Field ID");
        if TableRelationsMetadata.FindSet() then
            repeat
                Result += Format(TableRelationsMetadata."Related Table ID") + '|';
            until TableRelationsMetadata.Next() = 0;
        exit(DelChr(Result, '>', '|'));
    end;

    local procedure TestFieldIsInteger()
    var
        "Field": Record "Field";
    begin
        if Field.Get("Table ID", "Field ID") then
            if not (Field.Type in [Field.Type::BigInteger, Field.Type::Integer]) then
                Field.FieldError(Type, MustBeIntegersErr);
    end;

    local procedure ThrowErrorIfFieldRemoved()
    var
        "Field": Record "Field";
        TypeHelper: Codeunit "Type Helper";
    begin
        Field.Get("Table ID", "Field ID");
        TypeHelper.TestFieldIsNotObsolete(Field);
    end;

    procedure GetElementName(): Text[250]
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
    begin
        if "XML Field Name" <> '' then
            exit("XML Field Name");

        exit(ConfigXMLExchange.GetElementName("Field Name"));
    end;

    procedure GetValidatedElementName(): Text
    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
    begin
        exit(ConfigValidateMgt.CheckName(GetElementName()));
    end;

    local procedure GetUniqueElementName(FieldName: Text[30]): Text[30]
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        ElementName: Text[30];
        NewFieldName: Text;
    begin
        ElementName := CopyStr(ConfigXMLExchange.GetElementName(FieldName), 1, MaxStrLen(ElementName));
        ConfigPackageField.SetRange("Package Code", "Package Code");
        ConfigPackageField.SetRange("Table ID", "Table ID");
        ConfigPackageField.SetFilter("Field ID", '<>%1', "Field ID");
        ConfigPackageField.SetRange("XML Field Name", ElementName);
        if not ConfigPackageField.IsEmpty() then begin
            NewFieldName := IncStr(FieldName);
            if NewFieldName = '' then
                NewFieldName := FieldName + '1';
            exit(GetUniqueElementName(CopyStr(NewFieldName, 1, MaxStrLen(FieldName))));
        end;

        exit(ElementName);
    end;

    local procedure ValidateFieldIDTableRelation()
    var
        FieldRec: Record Field;
        ShouldValidate: Boolean;
    begin
        ShouldValidate := not Dimension;
        OnBeforeValidateFieldIDTableRelation(Rec, ShouldValidate);
        if ShouldValidate then
            FieldRec.Get("Table ID", "Field ID");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIncludeFieldOnValidateOnAfterCalcShouldRunCheck(var ConfigPackageField: Record "Config. Package Field"; var ShouldRunCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIncludeField(var ConfigPackageField: Record "Config. Package Field"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateValidateField(var ConfigPackageField: Record "Config. Package Field"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateFieldIDTableRelation(var ConfigPackageField: Record "Config. Package Field"; var ShouldValidate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateFieldOnValidateOnAfterCalcShouldRunCheck(var ConfigPackageField: Record "Config. Package Field"; var ShouldRunCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFieldErrorsOnAfterCalcShouldRunCheck(var ConfigPackageField: Record "Config. Package Field"; var ShouldRunCheck: Boolean)
    begin
    end;
}

