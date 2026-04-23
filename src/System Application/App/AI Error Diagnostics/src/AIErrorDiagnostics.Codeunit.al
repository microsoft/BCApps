// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI;

/// <summary>
/// Analyzes runtime errors using Claude Code CLI.
/// Given an error message, captures the call stack and returns a structured reason and suggestion.
/// OnPrem only.
/// </summary>
codeunit 4451 "AI Error Diagnostics"
{
    Access = Public;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AIErrorDiagnosticsImpl: Codeunit "AI Error Diagnostics Impl.";

    /// <summary>
    /// Analyzes an error by sending the error message and current call stack to Claude Code CLI.
    /// </summary>
    /// <param name="ErrorMessage">The error message to analyze.</param>
    /// <param name="Reason">Returns the reason why the error occurred.</param>
    /// <param name="Suggestion">Returns an actionable suggestion for how to fix the error.</param>
    /// <returns>True if the analysis succeeded, false on failure (timeout, CLI not found, parse error).</returns>
    procedure AnalyzeError(ErrorMessage: Text; var Reason: Text; var Suggestion: Text): Boolean
    begin
        exit(this.AIErrorDiagnosticsImpl.AnalyzeError(ErrorMessage, Reason, Suggestion));
    end;
}
