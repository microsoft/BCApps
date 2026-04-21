// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI;

using System;

codeunit 4451 "AI Error Diagnostics Impl."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ClaudeCliPathTxt: Label 'C:\Users\ventselartur\.claude\local\claude.exe', Locked = true;

    procedure AnalyzeError(ErrorMessage: Text; var Reason: Text; var Suggestion: Text): Boolean
    var
        CallStack: Text;
        Prompt: Text;
        CliOutput: Text;
    begin
        Reason := '';
        Suggestion := '';

        CallStack := SessionInformation.CallStack();
        Prompt := BuildPrompt(ErrorMessage, CallStack);
        if not InvokeClaude(Prompt, CliOutput) then
            exit(false);
        if not ParseResponse(CliOutput, Reason, Suggestion) then
            exit(false);
        exit(true);
    end;

    local procedure BuildPrompt(ErrorMessage: Text; CallStack: Text): Text
    var
        PromptBuilder: TextBuilder;
    begin
        PromptBuilder.AppendLine('You are an error diagnostics assistant for Microsoft Dynamics 365 Business Central.');
        PromptBuilder.AppendLine('');
        PromptBuilder.AppendLine('An error occurred with the following message:');
        PromptBuilder.AppendLine('<error_message>');
        PromptBuilder.AppendLine(ErrorMessage);
        PromptBuilder.AppendLine('</error_message>');
        PromptBuilder.AppendLine('');
        PromptBuilder.AppendLine('The call stack at the time of the error:');
        PromptBuilder.AppendLine('<call_stack>');
        PromptBuilder.AppendLine(CallStack);
        PromptBuilder.AppendLine('</call_stack>');
        PromptBuilder.AppendLine('');
        PromptBuilder.AppendLine('Analyze the error and provide:');
        PromptBuilder.AppendLine('- "reason": A clear explanation of why this error occurred.');
        PromptBuilder.AppendLine('- "suggestion": A concrete actionable suggestion for how to fix it.');
        exit(PromptBuilder.ToText());
    end;

    local procedure InvokeClaude(Prompt: Text; var CliOutput: Text): Boolean
    var
        Process: DotNet Process;
        StartInfo: DotNet ProcessStartInfo;
        StdOutReader: DotNet StreamReader;
        Arguments: Text;
        JsonSchema: Text;
        TimeoutMs: Integer;
        Success: Boolean;
    begin
        JsonSchema := '{"type":"object","properties":{"reason":{"type":"string"},"suggestion":{"type":"string"}},"required":["reason","suggestion"]}';

        StartInfo := StartInfo.ProcessStartInfo();
        StartInfo.FileName := ClaudeCliPathTxt;
        Arguments := '-p "' + EscapeDoubleQuotes(Prompt) + '" --output-format json --json-schema ''' + JsonSchema + ''' --bare';
        StartInfo.Arguments := Arguments;
        StartInfo.RedirectStandardOutput := true;
        StartInfo.UseShellExecute := false;
        StartInfo.CreateNoWindow := true;

        Process := Process.Process();
        Process.StartInfo := StartInfo;

        if not Process.Start() then
            exit(false);

        StdOutReader := Process.StandardOutput;
        CliOutput := StdOutReader.ReadToEnd();

        TimeoutMs := 45000;
        if not Process.WaitForExit(TimeoutMs) then begin
            Process.Kill();
            Process.Close();
            exit(false);
        end;

        Success := (Process.ExitCode = 0) and (CliOutput <> '');
        Process.Close();
        exit(Success);
    end;

    local procedure ParseResponse(CliOutput: Text; var Reason: Text; var Suggestion: Text): Boolean
    var
        ResponseJson: JsonObject;
        StructuredOutputToken: JsonToken;
        StructuredOutput: JsonObject;
        ReasonToken: JsonToken;
        SuggestionToken: JsonToken;
    begin
        if not ResponseJson.ReadFrom(CliOutput) then
            exit(false);
        if not ResponseJson.Get('structured_output', StructuredOutputToken) then
            exit(false);
        if not StructuredOutputToken.IsObject() then
            exit(false);
        StructuredOutput := StructuredOutputToken.AsObject();
        if not StructuredOutput.Get('reason', ReasonToken) then
            exit(false);
        if not StructuredOutput.Get('suggestion', SuggestionToken) then
            exit(false);
        Reason := ReasonToken.AsValue().AsText();
        Suggestion := SuggestionToken.AsValue().AsText();
        exit(true);
    end;

    local procedure EscapeDoubleQuotes(Input: Text): Text
    begin
        exit(Input.Replace('"', '\"'));
    end;
}
