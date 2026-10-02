// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Holds AIT-specific timing and token baselines for the current language-first data-driven case.
/// Generic dataset and case identity is owned by <c>Test Data Source Context</c> in the Test Runner app.
/// </summary>
codeunit 149033 "AIT Test Case State"
{
    SingleInstance = true;
    Access = Internal;

    var
        CaseStartTime: DateTime;
        CaseStartTokens: Integer;

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

    procedure Reset()
    begin
        Clear(CaseStartTime);
        Clear(CaseStartTokens);
    end;
}
