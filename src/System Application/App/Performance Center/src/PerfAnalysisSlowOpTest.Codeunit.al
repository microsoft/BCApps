// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Developer-facing helper that simulates a slow operation. Use it from the Performance
/// Center to validate that the monitoring pipeline catches slowness and that the AI
/// produces a sensible analysis. On each invocation the operation is either "fast-ish"
/// (sleeps 1-2 seconds) or calls <c>CheckLicense</c> which sleeps 10-15 seconds — the
/// kind of tail latency a user would typically report.
/// </summary>
codeunit 8433 "Perf. Analysis Slow Op Test"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure SlowOperation()
    var
        SleepMs: Integer;
    begin
        Randomize();
        if Random(2) = 1 then begin
            SleepMs := 1000 + Random(1000);
            Sleep(SleepMs);
        end else
            CheckLicense();
        Message(RanMsg);
    end;

    procedure CheckLicense()
    var
        SleepMs: Integer;
    begin
        Randomize();
        SleepMs := 10000 + Random(5000);
        Sleep(SleepMs);
    end;

    var
        RanMsg: Label 'Done.';
}
