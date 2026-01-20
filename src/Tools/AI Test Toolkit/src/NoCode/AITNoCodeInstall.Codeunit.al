// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Install codeunit that seeds default query schemas for known AI features.
/// </summary>
codeunit 149065 "AIT No Code Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    begin
        SeedDefaultSchemas();
    end;

    /// <summary>
    /// Seeds default query schemas for known AI features.
    /// Each feature defines the fields that make up its query structure.
    /// </summary>
    procedure SeedDefaultSchemas()
    begin
        // Agent Runtime feature - instructions, message, attachments
        SeedAgentRuntimeSchema();

        // Generic Copilot feature - question/context based
        SeedGenericCopilotSchema();

        // Add more feature schemas here as needed
    end;

    local procedure SeedAgentRuntimeSchema()
    var
        AITQuerySchema: Record "AIT Query Schema";
        SchemaJson: JsonObject;
        FieldsArray: JsonArray;
    begin
        if AITQuerySchema.Get('AGENT-RUNTIME') then
            exit;

        AITQuerySchema.Init();
        AITQuerySchema."Feature Code" := 'AGENT-RUNTIME';
        AITQuerySchema.Description := 'Business Central Agent Runtime Tests';
        AITQuerySchema."Default Codeunit ID" := 133940; // Generic Agent Test

        // Build schema: instructions (required multiline), message (optional text), attachment_files (optional file list)
        FieldsArray.Add(CreateFieldDef('instructions', 'Instructions', 'multilinetext', true, 'The instructions for the agent to follow.', ''));
        FieldsArray.Add(CreateFieldDef('message', 'Message', 'text', false, 'Optional incoming message from external user.', ''));
        FieldsArray.Add(CreateFieldDef('attachment_files', 'Attachment Files', 'filelist', false, 'Optional list of attachment files.', ''));
        FieldsArray.Add(CreateFieldDef('expect_annotations', 'Expect Annotations', 'boolean', false, 'Set to true to allow test to proceed despite annotation warnings.', ''));

        SchemaJson.Add('fields', FieldsArray);
        AITQuerySchema.SetSchemaJson(SchemaJson);
        AITQuerySchema.Insert(true);
    end;

    local procedure SeedGenericCopilotSchema()
    var
        AITQuerySchema: Record "AIT Query Schema";
        SchemaJson: JsonObject;
        FieldsArray: JsonArray;
    begin
        if AITQuerySchema.Get('COPILOT') then
            exit;

        AITQuerySchema.Init();
        AITQuerySchema."Feature Code" := 'COPILOT';
        AITQuerySchema.Description := 'Generic Copilot Feature Tests';

        // Build schema: question (required), context (optional)
        FieldsArray.Add(CreateFieldDef('question', 'Question', 'text', true, 'The question or prompt for the Copilot feature.', ''));
        FieldsArray.Add(CreateFieldDef('context', 'Context', 'multilinetext', false, 'Optional context to provide to the Copilot feature.', ''));

        SchemaJson.Add('fields', FieldsArray);
        AITQuerySchema.SetSchemaJson(SchemaJson);
        AITQuerySchema.Insert(true);
    end;

    local procedure CreateFieldDef(Name: Text; Label: Text; FieldType: Text; Required: Boolean; Description: Text; DefaultValue: Text): JsonObject
    var
        FieldDef: JsonObject;
    begin
        FieldDef.Add('name', Name);
        FieldDef.Add('label', Label);
        FieldDef.Add('type', FieldType);
        FieldDef.Add('required', Required);
        FieldDef.Add('description', Description);
        if DefaultValue <> '' then
            FieldDef.Add('default', DefaultValue);
        exit(FieldDef);
    end;
}
