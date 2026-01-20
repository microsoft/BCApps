// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Temporary table for editing validation entries for a test line.
/// Data is loaded from and saved back to Test Input JSON blobs.
/// This table should ONLY be used as a temporary table.
/// </summary>
table 149078 "AIT Validation Entry"
{
    Caption = 'AI Test Validation Entry';
    DataClassification = SystemMetadata;
    TableType = Temporary;
    ReplicateData = false;
    Extensible = false;
    Access = Internal;

    fields
    {
        field(1; "Dataset Code"; Code[100])
        {
            Caption = 'Dataset Code';
            ToolTip = 'Specifies the dataset this validation belongs to.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the test line this validation belongs to.';
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the validation entry number within the test line.';
        }
        field(10; "Validation Type"; Enum "AIT Validation Type")
        {
            Caption = 'Validation Type';
            ToolTip = 'Specifies the type of validation to perform.';
        }
        field(20; "Table Name"; Text[100])
        {
            Caption = 'Table Name';
            ToolTip = 'Specifies the table to validate records in (for Database/Message validation).';
        }
        field(21; "Expected Count"; Integer)
        {
            Caption = 'Expected Count';
            ToolTip = 'Specifies the expected number of records.';
        }
        field(22; "Name Prefix"; Text[100])
        {
            Caption = 'Name Prefix';
            ToolTip = 'Specifies filter records by name prefix.';
        }
        field(23; "Primary Name Field"; Text[100])
        {
            Caption = 'Primary Name Field';
            ToolTip = 'Specifies the primary name field if not "Name" (e.g., "Description" for Item table).';
        }
        field(30; "Validation Prompt"; Blob)
        {
            Caption = 'Validation Prompt';
            ToolTip = 'Specifies the LLM prompt to evaluate test output. Use {{response}} as placeholder.';
        }
        field(40; "Intervention Type"; Option)
        {
            Caption = 'Intervention Type';
            OptionCaption = 'Assistance,ReviewRecord,ReviewMessage';
            OptionMembers = Assistance,ReviewRecord,ReviewMessage;
            ToolTip = 'Specifies the expected intervention request type.';
        }
        field(50; "Field Validations JSON"; Blob)
        {
            Caption = 'Field Validations JSON';
            ToolTip = 'Specifies additional field validation criteria as JSON array.';
        }
    }

    keys
    {
        key(PK; "Dataset Code", "Line No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Gets the validation prompt text.
    /// </summary>
    procedure GetValidationPrompt(): Text
    var
        PromptInStream: InStream;
        PromptText: Text;
    begin
        CalcFields("Validation Prompt");
        if not "Validation Prompt".HasValue() then
            exit('');

        "Validation Prompt".CreateInStream(PromptInStream, TextEncoding::UTF8);
        PromptInStream.ReadText(PromptText);
        exit(PromptText);
    end;

    /// <summary>
    /// Sets the validation prompt text.
    /// </summary>
    procedure SetValidationPrompt(PromptText: Text)
    var
        PromptOutStream: OutStream;
    begin
        "Validation Prompt".CreateOutStream(PromptOutStream, TextEncoding::UTF8);
        PromptOutStream.WriteText(PromptText);
    end;

    /// <summary>
    /// Gets the field validations as a JsonArray.
    /// </summary>
    procedure GetFieldValidations(): JsonArray
    var
        FieldsInStream: InStream;
        FieldsText: Text;
        FieldsArray: JsonArray;
    begin
        CalcFields("Field Validations JSON");
        if not "Field Validations JSON".HasValue() then
            exit(FieldsArray);

        "Field Validations JSON".CreateInStream(FieldsInStream, TextEncoding::UTF8);
        FieldsInStream.ReadText(FieldsText);
        if FieldsText <> '' then
            FieldsArray.ReadFrom(FieldsText);
        exit(FieldsArray);
    end;

    /// <summary>
    /// Sets the field validations from a JsonArray.
    /// </summary>
    procedure SetFieldValidations(FieldsArray: JsonArray)
    var
        FieldsOutStream: OutStream;
        FieldsText: Text;
    begin
        FieldsArray.WriteTo(FieldsText);
        "Field Validations JSON".CreateOutStream(FieldsOutStream, TextEncoding::UTF8);
        FieldsOutStream.WriteText(FieldsText);
    end;

    /// <summary>
    /// Builds the validation JSON for the expected_data section.
    /// </summary>
    procedure BuildValidationJson(var ExpectedDataJson: JsonObject)
    var
        ValidateArray: JsonArray;
        ValidateObj: JsonObject;
        FieldsArray: JsonArray;
        ExistingToken: JsonToken;
    begin
        case "Validation Type" of
            "Validation Type"::DatabaseRecords:
                begin
                    ValidateObj.Add('count', "Expected Count");
                    ValidateObj.Add('table', "Table Name");
                    if "Name Prefix" <> '' then
                        ValidateObj.Add('name_prefix', "Name Prefix");
                    if "Primary Name Field" <> '' then
                        ValidateObj.Add('primary_name_field', "Primary Name Field");
                    FieldsArray := GetFieldValidations();
                    if FieldsArray.Count > 0 then
                        ValidateObj.Add('fields', FieldsArray);

                    // Append to existing array or create new one
                    if ExpectedDataJson.Get('validate_records_db', ExistingToken) then begin
                        ValidateArray := ExistingToken.AsArray();
                        ValidateArray.Add(ValidateObj);
                    end else begin
                        ValidateArray.Add(ValidateObj);
                        ExpectedDataJson.Add('validate_records_db', ValidateArray);
                    end;
                end;
            "Validation Type"::MessageContent:
                begin
                    ValidateObj.Add('count', "Expected Count");
                    ValidateObj.Add('table', "Table Name");
                    if "Name Prefix" <> '' then
                        ValidateObj.Add('name_prefix', "Name Prefix");
                    if "Primary Name Field" <> '' then
                        ValidateObj.Add('primary_name_field', "Primary Name Field");

                    if ExpectedDataJson.Get('validate_records_msg', ExistingToken) then begin
                        ValidateArray := ExistingToken.AsArray();
                        ValidateArray.Add(ValidateObj);
                    end else begin
                        ValidateArray.Add(ValidateObj);
                        ExpectedDataJson.Add('validate_records_msg', ValidateArray);
                    end;
                end;
            "Validation Type"::ValidationPrompt:
                ExpectedDataJson.Add('validation_prompt', GetValidationPrompt());
            "Validation Type"::InterventionRequest:
                case "Intervention Type" of
                    "Intervention Type"::Assistance:
                        ExpectedDataJson.Add('intervention_request_type', 'Assistance');
                    "Intervention Type"::ReviewRecord:
                        ExpectedDataJson.Add('intervention_request_type', 'ReviewRecord');
                    "Intervention Type"::ReviewMessage:
                        ExpectedDataJson.Add('intervention_request_type', 'ReviewMessage');
                end;
        end;
    end;

    /// <summary>
    /// Gets the next entry number for a new validation in the specified test line.
    /// </summary>
    procedure GetNextEntryNo(DatasetCode: Code[100]; LineNo: Integer): Integer
    var
        AITValidationEntry: Record "AIT Validation Entry";
    begin
        AITValidationEntry.SetRange("Dataset Code", DatasetCode);
        AITValidationEntry.SetRange("Line No.", LineNo);
        if AITValidationEntry.FindLast() then
            exit(AITValidationEntry."Entry No." + 1)
        else
            exit(1);
    end;

    /// <summary>
    /// Returns a display text summarizing this validation.
    /// </summary>
    procedure GetDisplayText(): Text
    begin
        case "Validation Type" of
            "Validation Type"::DatabaseRecords:
                exit(StrSubstNo(DbValidationLbl, "Expected Count", "Table Name"));
            "Validation Type"::MessageContent:
                exit(StrSubstNo(MsgValidationLbl, "Expected Count", "Table Name"));
            "Validation Type"::ValidationPrompt:
                exit('Custom Prompt');
            "Validation Type"::InterventionRequest:
                exit(StrSubstNo(InterventionValidationLbl, "Intervention Type"));
            else
                exit('None');
        end;
    end;

    var
        DbValidationLbl: Label 'DB: %1 x %2', Comment = '%1 = count, %2 = table name';
        MsgValidationLbl: Label 'Msg: %1 x %2', Comment = '%1 = count, %2 = table name';
        InterventionValidationLbl: Label 'Intervention: %1', Comment = '%1 = intervention type';
}
