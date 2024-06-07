// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

using System.AI;

codeunit 2018 "Magic Function" implements "AOAI Function"
{
    Access = Internal;

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
    begin
        Error(CompletionDeniedPhraseErr);
    end;

    procedure GetName(): Text
    begin
        exit(FunctionNameLbl);
    end;
}