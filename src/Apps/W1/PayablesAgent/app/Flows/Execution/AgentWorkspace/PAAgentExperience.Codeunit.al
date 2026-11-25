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
        SourceNotAvailableErr: Label 'The source of this task is no longer available.';
        SourceTextUnavailableMsg: Label 'There is no extracted source text, and this source cannot be extracted.';
        ExtractSourceTextQst: Label 'There is no extracted source text. Do you want to extract it now?';
        ReplaceSourceTextQst: Label 'Extracted source text already exists. Do you want to replace it?';
        SourceTextMsg: Label '%1', Comment = '%1 = extracted source text';

    internal procedure ExtractSourceText(var WorkItem: Codeunit "PA Work Item")
    begin
        if not WorkItem.CanExtractText() then
            Error(SourceNotAvailableErr);
        if WorkItem.GetExtractedText() <> '' then
            if not Confirm(ReplaceSourceTextQst, false) then
                exit;
        ExtractAndShowSourceText(WorkItem);
    end;

    internal procedure ShowSourceText(var WorkItem: Codeunit "PA Work Item")
    var
        SourceText: Text;
    begin
        SourceText := WorkItem.GetExtractedText();
        if SourceText <> '' then begin
            Message(SourceTextMsg, SourceText);
            exit;
        end;
        if not WorkItem.CanExtractText() then begin
            Message(SourceTextUnavailableMsg);
            exit;
        end;
        if not Confirm(ExtractSourceTextQst, false) then
            exit;
        ExtractAndShowSourceText(WorkItem);
    end;

    local procedure ExtractAndShowSourceText(var WorkItem: Codeunit "PA Work Item")
    var
        PdfTextExtraction: Codeunit "PA PDF Text Extraction";
    begin
        PdfTextExtraction.ExtractText(WorkItem);
        Message(SourceTextMsg, WorkItem.GetExtractedText());
    end;
}
