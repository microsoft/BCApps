// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Stores the identity of the data-driven test case currently being materialized and executed.
/// Data-source providers set the context so test handlers and result integrations can correlate
/// platform-generated cases with their backing dataset.
/// </summary>
codeunit 130463 "Test Data Source Context"
{
    SingleInstance = true;
    Access = Public;

    var
        CurrentDataSetIdentifier: Text[250];
        CurrentTestCaseIdentifier: Text[250];
        HasCurrentCase: Boolean;
        RunId: Guid;
        RunOwnerCodeunitId: Integer;

    procedure SetCurrent(DataSetIdentifier: Text; TestCaseIdentifier: Text)
    begin
        CurrentDataSetIdentifier := CopyStr(DataSetIdentifier, 1, MaxStrLen(CurrentDataSetIdentifier));
        CurrentTestCaseIdentifier := CopyStr(TestCaseIdentifier, 1, MaxStrLen(CurrentTestCaseIdentifier));
        HasCurrentCase := true;
    end;

    procedure TryGetCurrent(var DataSetIdentifier: Text; var TestCaseIdentifier: Text): Boolean
    begin
        if not HasCurrentCase then
            exit(false);

        DataSetIdentifier := CurrentDataSetIdentifier;
        TestCaseIdentifier := CurrentTestCaseIdentifier;
        exit(true);
    end;

    procedure ClearCurrent()
    begin
        Clear(CurrentDataSetIdentifier);
        Clear(CurrentTestCaseIdentifier);
        HasCurrentCase := false;
    end;

    procedure GetRunId(): Guid
    begin
        if IsNullGuid(RunId) then
            RunId := CreateGuid();

        exit(RunId);
    end;

    procedure IsRunActive(): Boolean
    begin
        exit(not IsNullGuid(RunId));
    end;

    procedure StartRun()
    begin
        ClearCurrent();
        RunId := CreateGuid();
        RunOwnerCodeunitId := 0;
    end;

    procedure StartRunIfNeeded(OwnerCodeunitId: Integer)
    begin
        if IsRunActive() then
            exit;

        StartRun();
        RunOwnerCodeunitId := OwnerCodeunitId;
    end;

    procedure EndRunIfOwned(OwnerCodeunitId: Integer)
    begin
        if RunOwnerCodeunitId = OwnerCodeunitId then
            EndRun();
    end;

    procedure EndRun()
    begin
        ClearCurrent();
        Clear(RunId);
        RunOwnerCodeunitId := 0;
    end;
}
