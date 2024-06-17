// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

using System.Azure.KeyVault;
using System.Telemetry;

codeunit 2019 "Entity Text Prompts"
{
    Access = Internal;

    [NonDebuggable]
    internal procedure GetAzureKeyVaultSecret(var SecretValue: Text; SecretName: Text)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(SecretName, SecretValue) then begin
            FeatureTelemetry.LogError('', 'Entity Text', 'Get prompt from Key Vault', TelemetryConstructingPromptFailedErr);
            Error(ConstructingPromptFailedErr);
        end;
    end;

    [NonDebuggable]
    internal procedure GetGenerateProdMktAdFuncPrompt(TextFormat: Enum "Entity Text Format"): Text
    var
        PromptObject: JsonObject;
        FunctPropArrayToken: JsonToken;
        FuncPropArray: JsonArray;
        FunctionPropObject: JsonToken;
        BCETGenerateProdMAdFuncPrompt: Text;
        BCETPromptObject: Text;
    begin
        GetAzureKeyVaultSecret(BCETPromptObject, 'BCETPromptObject');
        PromptObject.ReadFrom(BCETPromptObject);
        PromptObject.Get('function-properties', FunctPropArrayToken);
        FuncPropArray := FunctPropArrayToken.AsArray();
        FuncPropArray.Get(TextFormat.AsInteger(), FunctionPropObject);

        GetAzureKeyVaultSecret(BCETGenerateProdMAdFuncPrompt, 'BCETGenerateProdMAdFuncPrompt');
        BCETGenerateProdMAdFuncPrompt := StrSubstNo(BCETGenerateProdMAdFuncPrompt, Format(FunctionPropObject));

        exit(BCETGenerateProdMAdFuncPrompt);
    end;

    [NonDebuggable]
    internal procedure GetMagicFunctionPrompt(): Text
    var
        BCETMagicFunctionPrompt: Text;
    begin
        GetAzureKeyVaultSecret(BCETMagicFunctionPrompt, 'BCETMagicFunctionPrompt');
        exit(BCETMagicFunctionPrompt);
    end;

    [NonDebuggable]
    procedure BuildPrompts(FactsList: Text; Category: Text; Tone: Enum "Entity Text Tone"; TextFormat: Enum "Entity Text Format"; TextEmphasis: Enum "Entity Text Emphasis"; var SystemPrompt: Text; var UserPrompt: Text)
    var
        EntityTextAOAISettings: Codeunit "Entity Text AOAI Settings";
        PromptObject: JsonObject;
        SystemPromptJson: JsonToken;
        UserPromptJson: JsonToken;
        BCETPromptObject: Text;
        BCETSafetyPrompt: Text;
        LanguageName: Text;
        NewLineChar: Char;
    begin
        NewLineChar := 10;
        LanguageName := EntityTextAOAISettings.GetLanguageName();

        GetAzureKeyVaultSecret(BCETPromptObject, 'BCETPromptObject');
        PromptObject.ReadFrom(BCETPromptObject);

        PromptObject.Get('system', SystemPromptJson);
        PromptObject.Get('user', UserPromptJson);

        SystemPrompt := BuildSinglePrompt(SystemPromptJson.AsObject(), LanguageName, FactsList, Category, Tone, TextFormat, TextEmphasis);
        UserPrompt := BuildSinglePrompt(UserPromptJson.AsObject(), LanguageName, FactsList, Category, Tone, TextFormat, TextEmphasis);

        GetAzureKeyVaultSecret(BCETSafetyPrompt, 'BCETSafetyPrompt');
        SystemPrompt := StrSubstNo(BCETSafetyPrompt, NewLineChar) + SystemPrompt;
    end;

    [NonDebuggable]
    local procedure BuildSinglePrompt(PromptInfo: JsonObject; LanguageName: Text; FactsList: Text; Category: Text; Tone: Enum "Entity Text Tone"; TextFormat: Enum "Entity Text Format"; TextEmphasis: Enum "Entity Text Emphasis") Prompt: Text
    var
        PromptHints: JsonToken;
        PromptOrder: JsonToken;
        PromptHint: JsonToken;
        HintName: Text;
        NewLineChar: Char;
        PromptIndex: Integer;
    begin
        NewLineChar := 10;

        PromptInfo.Get('prompt', PromptHints);
        PromptInfo.Get('order', PromptOrder);

        foreach PromptHint in PromptOrder.AsArray() do begin
            HintName := PromptHint.AsValue().AsText();
            if PromptHints.AsObject().Get(HintName, PromptHint) then begin
                // found the hint
                if PromptHint.IsArray() then begin
                    PromptIndex := 0; // default value
                    case HintName of
                        'tone':
                            PromptIndex := Tone.AsInteger();
                        'format':
                            PromptIndex := TextFormat.AsInteger();
                        'emphasis':
                            PromptIndex := TextEmphasis.AsInteger();
                    end;

                    if not PromptHint.AsArray().Get(PromptIndex, PromptHint) then
                        PromptHint.AsArray().Get(0, PromptHint);
                end;

                Prompt += StrSubstNo(PromptHint.AsValue().AsText(), NewLineChar, LanguageName, FactsList, Category);
            end;
        end;
    end;

    [TryFunction]
    [NonDebuggable]
    procedure HasPromptInfo()
    var
        BCETPromptObjectLbl: Text;
    begin
        GetAzureKeyVaultSecret(BCETPromptObjectLbl, 'BCETPromptObjectLbl');
    end;

    var
        ConstructingPromptFailedErr: label 'There was an error with sending the call to Copilot. Log a Business Central support request about this.', Comment = 'Copilot is a Microsoft service name and must not be translated';
        TelemetryConstructingPromptFailedErr: label 'There was an error with constructing the chat completion prompt from the Key Vault.', Locked = true;
}