// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

/// <summary>
/// Bridges the dataset lineage of the currently executing language-first data-driven case to the AIT logging
/// pipeline. Under the classic path the current row is carried on the platform Test Method Line's Data Input
/// fields; under <c>[TestDataSource]</c> the platform drives the fan-out and those fields are empty, so the
/// per-case context records its row here (single-instance, in-memory) for <c>AddLogEntry</c> to pick up.
/// </summary>
codeunit 149033 "AIT DD Current Case"
{
    SingleInstance = true;
    Access = Internal;

    var
        CurrentGroupCode: Code[100];
        CurrentInputCode: Code[100];
        HasCase: Boolean;

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
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterRunTestSuite', '', false, false)]
    local procedure ClearOnAfterRunTestSuite()
    begin
        ClearCurrent();
    end;
}
