// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

using System.AI;
using System.Telemetry;

codeunit 2018 "Magic Function" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FunctionNameLbl: Label 'magic_function', Locked = true;
        CompletionDeniedPhraseErr: Label 'Sorry, we could not generate a good suggestion for this. Review the information provided, consider your choice of words, and try again.', Locked = true;

    [NonDebuggable]
    procedure GetPrompt(): JsonObject
    var
        Prompt: Codeunit "Entity Text Prompts";
        PromptJson: JsonObject;
    begin
        PromptJson.ReadFrom(Prompt.GetMagicFunctionPrompt());
        exit(PromptJson);
    end;

    [NonDebuggable]
    procedure Execute(Arguments: JsonObject): Variant
    var
        EntityTextImpl: Codeunit "Entity Text Impl.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000N59', EntityTextImpl.GetFeatureName(), 'function_call: magic_function');
        exit(CompletionDeniedPhraseErr);
    end;

    procedure GetName(): Text
    begin
        exit(FunctionNameLbl);
    end;
}