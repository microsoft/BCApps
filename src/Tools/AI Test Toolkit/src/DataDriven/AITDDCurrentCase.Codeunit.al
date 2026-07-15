// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

/// <summary>
/// Bridges the dataset lineage and per-case outcome of the currently executing language-first (<c>[TestDataSource]</c>)
/// data-driven case to the AIT logging pipeline, and owns the out-of-isolation flush of the per-case log entry when the
/// eval runs on the platform test runner (no AIT suite).
///
/// Under the classic app-based path the current row is carried on the platform Test Method Line's Data Input fields;
/// under <c>[TestDataSource]</c> the platform drives the fan-out and those fields are empty, so the per-case context
/// records its row here (single-instance, in-memory).
///
/// For the platform-runner path <see cref="AIT Test Handler"/> records the per-case outcome here from inside the
/// function isolation scope (where DB writes would be rolled back); the <c>OnAfterTestMethodRun</c> subscriber below
/// drains it to <see cref="AIT Log Entry"/> from <em>outside</em> that scope so the log survives the case rollback
/// (decision C8-A).
/// </summary>
codeunit 149033 "AIT DD Current Case"
{
    SingleInstance = true;
    Access = Internal;

    var
        CurrentGroupCode: Code[100];
        CurrentInputCode: Code[100];
        HasCase: Boolean;
        RunId: Guid;
        CaseStartTime: DateTime;
        CaseStartTokens: Integer;
        PendingCodeunitId: Integer;
        PendingProcedureName: Text;
        PendingCaseName: Text;
        PendingSuccess: Boolean;
        HasPendingCase: Boolean;

    /// <summary>Records the start time and token baseline for the case that is about to run.</summary>
    procedure SetCaseStart(StartTime: DateTime; StartTokens: Integer)
    begin
        CaseStartTime := StartTime;
        CaseStartTokens := StartTokens;
    end;

    /// <summary>Returns the start time and token baseline recorded for the current case.</summary>
    procedure GetCaseStart(var StartTime: DateTime; var StartTokens: Integer)
    begin
        StartTime := CaseStartTime;
        StartTokens := CaseStartTokens;
    end;

    /// <summary>
    /// Buffers the identity of a language-first case executing on the platform test runner so its log entry can be
    /// written from the out-of-isolation <c>OnAfterTestMethodRun</c> seam. Called by
    /// <see cref="AIT Test Handler"/>.OnBeforeTestCaseRun.
    /// </summary>
    procedure BeginPendingCase(CodeunitId: Integer; ProcedureName: Text; CaseName: Text)
    begin
        PendingCodeunitId := CodeunitId;
        PendingProcedureName := ProcedureName;
        PendingCaseName := CaseName;
        PendingSuccess := false;
        HasPendingCase := true;
    end;

    /// <summary>Records the pass/fail outcome of the buffered case. Called by <see cref="AIT Test Handler"/>.OnAfterTestCaseRun.</summary>
    procedure SetPendingSuccess(Success: Boolean)
    begin
        PendingSuccess := Success;
    end;

    /// <summary>Records the dataset row of the case that is about to be (or is being) executed.</summary>
    procedure SetCurrent(GroupCode: Code[100]; InputCode: Code[100])
    begin
        CurrentGroupCode := GroupCode;
        CurrentInputCode := InputCode;
        HasCase := true;
    end;

    /// <summary>Returns the current data-driven case's dataset row, if one has been recorded.</summary>
    procedure TryGetCurrent(var GroupCode: Code[100]; var InputCode: Code[100]): Boolean
    begin
        if not HasCase then
            exit(false);
        GroupCode := CurrentGroupCode;
        InputCode := CurrentInputCode;
        exit(true);
    end;

    procedure ClearCurrent()
    begin
        Clear(CurrentGroupCode);
        Clear(CurrentInputCode);
        HasCase := false;
        ClearPendingCase();
    end;

    local procedure ClearPendingCase()
    begin
        Clear(PendingCodeunitId);
        Clear(PendingProcedureName);
        Clear(PendingCaseName);
        PendingSuccess := false;
        HasPendingCase := false;
    end;

    /// <summary>Session-scoped run identifier used to correlate per-case log entries when a data-driven test
    /// runs directly on the platform test runner (no AIT test suite context).</summary>
    procedure GetRunId(): Guid
    begin
        if IsNullGuid(RunId) then
            RunId := CreateGuid();
        exit(RunId);
    end;

    /// <summary>
    /// Flushes the per-case log entry buffered by <see cref="AIT Test Handler"/> to <see cref="AIT Log Entry"/>. This
    /// subscriber fires once per data-driven case but — unlike the handler's OnAfterTestCaseRun — runs <em>outside</em>
    /// the function isolation scope, so the written log survives the test-case rollback (decision C8-A). It is a no-op
    /// unless the handler buffered a case (a language-first eval running without an AIT suite). NOTE: this seam is
    /// raised by the "Test Runner - Mgt" runner (AL Test Tool / Test Suite Mgt); the pure platform test-execution path
    /// (e.g. the al CLI) does not raise it, so persistence there requires the platform out-of-isolation persist hook
    /// tracked as a follow-up.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterTestMethodRun', '', false, false)]
    local procedure FlushPendingCaseOnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
    begin
        if not HasPendingCase then
            exit;

        // Under an AIT suite the classic AddLogEntry path already logged this case; avoid a duplicate.
        if AITTestRunIteration.IsRunningUnderAITSuite() then begin
            ClearPendingCase();
            exit;
        end;

        AITTestSuiteMgt.AddDataDrivenLogEntry(PendingCodeunitId, PendingProcedureName, PendingCaseName, PendingSuccess);
        ClearPendingCase();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterRunTestSuite', '', false, false)]
    local procedure ClearOnAfterRunTestSuite()
    begin
        ClearCurrent();
    end;
}
