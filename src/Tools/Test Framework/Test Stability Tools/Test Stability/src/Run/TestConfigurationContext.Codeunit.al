// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.TestTools.TestRunner;

/// <summary>
/// The current suite's configuration, loaded before test permissions are applied.
/// </summary>
codeunit 130482 "Test Configuration Context"
{
    SingleInstance = true;
    Permissions = tabledata "AL Test Suite" = r,
                  tabledata "Test Configuration" = r;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CurrentConfiguration: Record "Test Configuration";
        CurrentSuiteName: Code[10];
        InitialWorkDate: Date;
        CurrentTestCodeunit: Integer;
        HandlerError: Text;

    internal procedure Initialize(SuiteName: Code[10])
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        Reset();
        ALTestSuite.Get(SuiteName);
        if ALTestSuite."Created From Suite" = '' then
            exit;

        CurrentConfiguration.Get(ALTestSuite."Created From Suite", ALTestSuite.Configuration);
        CurrentSuiteName := SuiteName;
        InitialWorkDate := WorkDate();
    end;

    procedure GetConfiguration(var TestConfiguration: Record "Test Configuration")
    begin
        TestConfiguration := CurrentConfiguration;
    end;

    procedure GetInitialWorkDate(): Date
    begin
        exit(InitialWorkDate);
    end;

    internal procedure IsCurrentSuite(SuiteName: Code[10]): Boolean
    begin
        exit((CurrentSuiteName <> '') and (CurrentSuiteName = SuiteName));
    end;

    internal procedure BeginCodeunit(CodeunitId: Integer)
    begin
        CurrentTestCodeunit := CodeunitId;
        Clear(HandlerError);
    end;

    internal procedure IsCurrentCodeunit(CodeunitId: Integer): Boolean
    begin
        exit((CurrentTestCodeunit <> 0) and (CurrentTestCodeunit = CodeunitId));
    end;

    internal procedure HasActiveCodeunit(): Boolean
    begin
        exit(CurrentTestCodeunit <> 0);
    end;

    internal procedure SetHandlerError(ErrorText: Text)
    begin
        HandlerError := ErrorText;
    end;

    internal procedure GetHandlerError(): Text
    begin
        exit(HandlerError);
    end;

    internal procedure EndCodeunit()
    begin
        Clear(CurrentTestCodeunit);
        Clear(HandlerError);
    end;

    internal procedure Reset()
    begin
        EndCodeunit();
        Clear(CurrentConfiguration);
        Clear(CurrentSuiteName);
        Clear(InitialWorkDate);
    end;
}
