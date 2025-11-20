// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.IO;

table 1302 "Dimensions Template"
{
    Caption = 'Dimensions Template';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if xRec."Dimension Code" <> "Dimension Code" then begin
                    "Dimension Value Code" := '';
                    "Value Posting" := "Value Posting"::" ";
                end;
            end;
        }
        field(4; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"),
                                                         Blocked = const(false));
        }
        field(5; "Value Posting"; Enum "Default Dimension Value Posting Type")
        {
            Caption = 'Value Posting';

            trigger OnValidate()
            begin
                if "Value Posting" = "Value Posting"::"No Code" then
                    TestField("Dimension Value Code", '');
            end;
        }
        field(50; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                Description := GetParentTemplateCode();
            end;
        }
        field(51; "Table Id"; Integer)
        {
            Caption = 'Table Id';

            trigger OnValidate()
            var
                TableIdFilter: Text;
            begin
                if "Table Id" = 0 then begin
                    TableIdFilter := GetFilter("Table Id");
                    Evaluate("Table Id", TableIdFilter);
                end;
            end;
        }
        field(52; "Master Record Template Code"; Code[10])
        {
            Caption = 'Master Record Template Code';
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
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        if ConfigTemplateHeader.Get(Code) then begin
            ConfigTemplateManagement.RemoveRelatedTemplate("Master Record Template Code", Code);
            ConfigTemplateHeader.Delete(true);
        end;
    end;

    trigger OnInsert()
    begin
        "Master Record Template Code" := GetParentTemplateCode();
        Validate(Description);
        Validate("Table Id");
        InsertConfigurationTemplateHeaderAndLines();
    end;

    trigger OnModify()
    var
        FieldRefArray: array[3] of FieldRef;
        RecRef: RecordRef;
    begin
        TestField(Code);
        Validate("Table Id");

        RecRef.GetTable(Rec);
        CreateFieldRefArray(FieldRefArray, RecRef);
        ConfigTemplateManagement.UpdateConfigTemplateAndLines(Code, Description, Database::"Default Dimension", FieldRefArray);
    end;

    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";

    local procedure CreateFieldRefArray(var FieldRefArray: array[3] of FieldRef; RecRef: RecordRef)
    var
        I: Integer;
    begin
        I := 1;

        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Dimension Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Dimension Value Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Value Posting")));
        OnAfterCreateFieldRefArray(FieldRefArray, RecRef);
    end;

    local procedure AddToArray(var FieldRefArray: array[23] of FieldRef; var I: Integer; CurrFieldRef: FieldRef)
    begin
        FieldRefArray[I] := CurrFieldRef;
        I += 1;
    end;

    procedure InitializeTemplatesFromMasterRecordTemplate(MasterRecordTemplateCode: Code[10]; var TempDimensionsTemplate: Record "Dimensions Template" temporary; TableID: Integer)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", MasterRecordTemplateCode);
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::"Related Template");

        if ConfigTemplateLine.FindSet() then
            repeat
                ConfigTemplateHeader.Get(ConfigTemplateLine."Template Code");
                InitializeTempRecordFromConfigTemplate(TempDimensionsTemplate, ConfigTemplateHeader, MasterRecordTemplateCode, TableID);
            until ConfigTemplateLine.Next() = 0;
    end;

    procedure InitializeTempRecordFromConfigTemplate(var TempDimensionsTemplate: Record "Dimensions Template" temporary; ConfigTemplateHeader: Record "Config. Template Header"; MasterRecordTemplateCode: Code[10]; TableID: Integer)
    var
        RecRef: RecordRef;
    begin
        TempDimensionsTemplate.Init();
        TempDimensionsTemplate.Code := ConfigTemplateHeader.Code;
        TempDimensionsTemplate.Description := ConfigTemplateHeader.Description;
        TempDimensionsTemplate."Master Record Template Code" := MasterRecordTemplateCode;
        TempDimensionsTemplate."Dimension Code" := GetDefaultDimensionCode(ConfigTemplateHeader);
        TempDimensionsTemplate."Table Id" := TableID;
        TempDimensionsTemplate.Insert();

        RecRef.GetTable(TempDimensionsTemplate);

        ConfigTemplateManagement.ApplyTemplateLinesWithoutValidation(ConfigTemplateHeader, RecRef);

        RecRef.SetTable(TempDimensionsTemplate);
    end;

    local procedure InsertConfigurationTemplateHeaderAndLines()
    var
        FieldRefArray: array[3] of FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        CreateFieldRefArray(FieldRefArray, RecRef);
        ConfigTemplateManagement.CreateConfigTemplateAndLines(Code, Description, Database::"Default Dimension", FieldRefArray);
        ConfigTemplateManagement.AddRelatedTemplate(GetParentTemplateCode(), Code);
    end;

    procedure InsertDimensionsFromTemplates(ConfigTemplateHeader: Record "Config. Template Header"; MasterRecordNo: Code[20]; TableID: Integer)
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::"Related Template");
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);

        if ConfigTemplateLine.FindSet() then
            repeat
                ConfigTemplateHeader.Get(ConfigTemplateLine."Template Code");
                if ConfigTemplateHeader."Table ID" = Database::"Default Dimension" then
                    InsertDimensionFromTemplate(ConfigTemplateHeader, MasterRecordNo, TableID);
            until ConfigTemplateLine.Next() = 0;
    end;

    local procedure InsertDimensionFromTemplate(ConfigTemplateHeader: Record "Config. Template Header"; MasterRecordNo: Code[20]; TableID: Integer)
    var
        DefaultDimension: Record "Default Dimension";
        ConfigTemplateMgt: Codeunit "Config. Template Management";
        RecRef: RecordRef;
    begin
        DefaultDimension.Init();
        DefaultDimension."No." := MasterRecordNo;
        DefaultDimension."Table ID" := TableID;
        DefaultDimension."Dimension Code" := GetDefaultDimensionCode(ConfigTemplateHeader);
        if not DefaultDimension.Find() then
            DefaultDimension.Insert();

        RecRef.GetTable(DefaultDimension);
        ConfigTemplateMgt.UpdateRecord(ConfigTemplateHeader, RecRef);
        RecRef.SetTable(DefaultDimension);
    end;

    local procedure GetDefaultDimensionCode(ConfigTemplateHeader: Record "Config. Template Header"): Text[20]
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.SetRange("Field ID", FieldNo("Dimension Code"));
        ConfigTemplateLine.FindFirst();

        exit(ConfigTemplateLine."Default Value");
    end;

    local procedure GetParentTemplateCode(): Text[10]
    begin
        exit(GetFilter("Master Record Template Code"));
    end;

    procedure CreateTemplatesFromExistingMasterRecord(MasterRecordNo: Code[20]; MasterRecordTemplateCode: Code[10]; TableID: Integer)
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("No.", MasterRecordNo);
        DefaultDimension.SetRange("Table ID", TableID);

        if DefaultDimension.FindSet() then
            repeat
                CreateTemplateFromExistingDefaultDimension(DefaultDimension, MasterRecordTemplateCode);
            until DefaultDimension.Next() = 0;
    end;

    local procedure CreateTemplateFromExistingDefaultDimension(DefaultDimension: Record "Default Dimension"; MasterRecordTemplateCode: Code[10])
    var
        RecRef: RecordRef;
        FieldRefArray: array[3] of FieldRef;
        NewTemplateCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTemplateFromExistingDefaultDimension(DefaultDimension, MasterRecordTemplateCode, IsHandled);
        if IsHandled then
            exit;

        RecRef.GetTable(DefaultDimension);
        CreateFieldRefArray(FieldRefArray, RecRef);

        ConfigTemplateManagement.CreateConfigTemplateAndLines(
          NewTemplateCode, MasterRecordTemplateCode, Database::"Default Dimension", FieldRefArray);
        ConfigTemplateManagement.AddRelatedTemplate(MasterRecordTemplateCode, NewTemplateCode);
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterCreateFieldRefArray(var FieldRefArray: array[23] of FieldRef; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTemplateFromExistingDefaultDimension(DefaultDimension: Record "Default Dimension"; MasterRecordTemplateCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

