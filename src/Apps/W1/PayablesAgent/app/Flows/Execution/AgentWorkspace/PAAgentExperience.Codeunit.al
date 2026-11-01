// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

codeunit 3335 "PA Agent Experience"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
#if DEVELOPMENT
        DevelopmentSettings: Codeunit "PA Development Settings";
#endif
        SourceNotAvailableErr: Label 'The source of this task is no longer available.';
        SourceTextUnavailableMsg: Label 'There is no extracted source text, and this source cannot be extracted.';
        ExtractSourceTextQst: Label 'There is no extracted source text. Do you want to extract it now?';
        ReplaceSourceTextQst: Label 'Extracted source text already exists. Do you want to replace it?';
        SourceTextMsg: Label '%1', Comment = '%1 = extracted source text';

    internal procedure ExtractSourceText(var Task: Codeunit "Payables Agent Task")
    begin
        if not Task.CanExtractText() then
            Error(SourceNotAvailableErr);
        if Task.GetSourceText() <> '' then
            if not Confirm(ReplaceSourceTextQst, false) then
                exit;
        ExtractAndShowSourceText(Task);
    end;

    internal procedure ShowSourceText(var Task: Codeunit "Payables Agent Task")
    var
        SourceText: Text;
    begin
        SourceText := Task.GetSourceText();
        if SourceText <> '' then begin
            Message(SourceTextMsg, SourceText);
            exit;
        end;
        if not Task.CanExtractText() then begin
            Message(SourceTextUnavailableMsg);
            exit;
        end;
        if not Confirm(ExtractSourceTextQst, false) then
            exit;
        ExtractAndShowSourceText(Task);
    end;

    local procedure ExtractAndShowSourceText(var Task: Codeunit "Payables Agent Task")
    var
        PdfTextExtraction: Codeunit "PA PDF Text Extraction";
    begin
        PdfTextExtraction.ExtractText(Task);
        Message(SourceTextMsg, Task.GetSourceText());
    end;

    internal procedure IsActive(): Boolean
    var
        PayablesAgent: Codeunit "Payables Agent Metadata";
        AgentTaskId: BigInteger;
    begin
        if PayablesAgent.IsPayablesAgentSession(AgentTaskId) then
            exit(true);
#if DEVELOPMENT
        exit(DevelopmentSettings.SimulateAgentExperience());
#else
        exit(false);
#endif
    end;
}
