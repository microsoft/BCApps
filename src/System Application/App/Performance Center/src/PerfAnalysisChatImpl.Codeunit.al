// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Backs the Performance Analysis Chat PromptDialog. Each question is sent as an
/// independent LLM call that includes the full scenario context and the prior
/// conclusion, so the user only sees their question and the reply.
/// </summary>
codeunit 8417 "Perf. Analysis Chat Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    SingleInstance = false;
    Permissions = tabledata "Performance Analysis" = R;

    var
        Analysis: Record "Performance Analysis";
        AnalysisSet: Boolean;

    procedure Initialize(var AnalysisRec: Record "Performance Analysis")
    begin
        Analysis := AnalysisRec;
        AnalysisSet := true;
    end;

    procedure Ask(UserText: Text) Reply: Text
    var
        Ai: Codeunit "Perf. Analysis AI";
    begin
        if not AnalysisSet then
            exit('');
        Reply := Ai.AskAboutAnalysis(Analysis, UserText);
        if Reply = '' then
            Reply := Ai.GetLastError();
    end;
}
