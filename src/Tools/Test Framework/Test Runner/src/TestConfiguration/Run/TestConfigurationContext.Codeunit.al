// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// The current suite's configuration, loaded before test permissions are applied.
/// </summary>
codeunit 130469 "Test Configuration Context"
{
    SingleInstance = true;
    Permissions = tabledata "AL Test Suite" = r,
                  tabledata "Test Configuration" = r;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CurrentConfiguration: Record "Test Configuration";
        CurrentSuiteName: Code[10];

    internal procedure Initialize(SuiteName: Code[10])
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        Reset();
        ALTestSuite.Get(SuiteName);
        if ALTestSuite."Created From Suite" <> '' then
            CurrentConfiguration.Get(ALTestSuite."Created From Suite", ALTestSuite.Configuration);
        CurrentSuiteName := SuiteName;
    end;

    procedure GetConfiguration(var TestConfiguration: Record "Test Configuration")
    begin
        TestConfiguration := CurrentConfiguration;
    end;

    internal procedure IsCurrentSuite(SuiteName: Code[10]): Boolean
    begin
        exit((CurrentSuiteName <> '') and (CurrentSuiteName = SuiteName));
    end;

    internal procedure Reset()
    begin
        Clear(CurrentConfiguration);
        Clear(CurrentSuiteName);
    end;
}
