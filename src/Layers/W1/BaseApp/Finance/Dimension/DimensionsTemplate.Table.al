// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.IO;

/// <summary>
/// Stores dimension template definitions for automated default dimension assignment during master record creation.
/// Enables configuration of dimension patterns that can be applied to new master data records through templates.
/// </summary>
/// <remarks>
/// Integrates with configuration templates to provide dimension defaults during record setup processes.
/// Supports dimension template inheritance and bulk application for master data initialization workflows.
/// </remarks>
table 1302 "Dimensions Template"
{
    Caption = 'Dimensions Template';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the dimension template configuration.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// Dimension code for which the template defines default assignment rules.
        /// </summary>
        field(3; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            ToolTip = 'Specifies the code for the default dimension.';
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
        /// <summary>
        /// Specific dimension value code to be assigned when applying this template.
        /// </summary>
        field(4; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            ToolTip = 'Specifies the dimension value code to suggest as the default dimension.';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"),
                                                         Blocked = const(false));
        }
        /// <summary>
        /// Posting behavior for the dimension value assignment from this template.
        /// </summary>
        field(5; "Value Posting"; Enum "Default Dimension Value Posting Type")
        {
            Caption = 'Value Posting';
            ToolTip = 'Specifies how default dimensions and their values must be used.';

            trigger OnValidate()
            begin
                if "Value Posting" = "Value Posting"::"No Code" then
                    TestField("Dimension Value Code", '');
            end;
        }
        /// <summary>
        /// Descriptive text for the dimension template configuration and usage purpose.
        /// </summary>
        field(50; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                Description := GetParentTemplateCode();
            end;
        }
        /// <summary>
        /// Table ID of the master data table for which this dimension template applies.
        /// </summary>
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
        /// <summary>
        /// Master record template code that this dimension template is associated with for coordinated application.
        /// </summary>
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

    /// <summary>
    /// Initializes dimension templates from a master record template for coordinated record creation.
    /// Creates temporary dimension template records based on template configuration relationships.
    /// </summary>
    /// <param name="MasterRecordTemplateCode">Master record template code to process</param>
    /// <param name="TempDimensionsTemplate">Temporary dimension template records to populate</param>
    /// <param name="TableID">Table ID for the target master data table</param>
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

    /// <summary>
    /// Initializes a temporary dimension template record from a configuration template header.
    /// Applies template field values and establishes relationships for dimension automation.
    /// </summary>
    /// <param name="TempDimensionsTemplate">Temporary dimension template record to initialize</param>
    /// <param name="ConfigTemplateHeader">Configuration template header providing field values</param>
    /// <param name="MasterRecordTemplateCode">Master record template code for association</param>
    /// <param name="TableID">Table ID for the target master data table</param>
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

    /// <summary>
    /// Inserts default dimensions for a master record using configured dimension templates.
    /// Applies all related dimension templates to establish complete dimension setup for new records.
    /// </summary>
    /// <param name="ConfigTemplateHeader">Configuration template header containing dimension template relationships</param>
    /// <param name="MasterRecordNo">Master record number for dimension assignment</param>
    /// <param name="TableID">Table ID of the master data table</param>
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

    /// <summary>
    /// Creates dimension templates from an existing master record's default dimension configuration.
    /// Enables template generation based on proven dimension setups for replication purposes.
    /// </summary>
    /// <param name="MasterRecordNo">Master record number to copy dimensions from</param>
    /// <param name="MasterRecordTemplateCode">Master record template code for association</param>
    /// <param name="TableID">Table ID of the master data table</param>
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

    /// <summary>
    /// Integration event raised before creating template from existing default dimension record.
    /// Enables customization of template creation logic for default dimension automation.
    /// </summary>
    /// <param name="DefaultDimension">Default dimension record being processed for template creation</param>
    /// <param name="MasterRecordTemplateCode">Master record template code for association</param>
    /// <param name="IsHandled">Set to true to skip standard template creation processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTemplateFromExistingDefaultDimension(DefaultDimension: Record "Default Dimension"; MasterRecordTemplateCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

