// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.AI;

/// <summary>
/// Backs the Performance Analysis Chat PromptDialog. Keeps the chat history for the
/// lifetime of the page and delegates the actual AI call to "Perf. Analysis AI".
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
        Messages: Codeunit "AOAI Chat Messages";
        Primed: Boolean;

    procedure Initialize(var AnalysisRec: Record "Performance Analysis")
    var
        Ai: Codeunit "Perf. Analysis AI";
    begin
        Analysis := AnalysisRec;
        Clear(Messages);
        Ai.PrimeChat(Analysis, Messages);
        Primed := true;
    end;

    procedure Ask(UserText: Text) Reply: Text
    var
        Ai: Codeunit "Perf. Analysis AI";
    begin
        if not Primed then
            Initialize(Analysis);
        Reply := Ai.SendChat(Analysis, Messages, UserText);
        if Reply = '' then
            Reply := Ai.GetLastError();
    end;
}
