// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

codeunit 149045 "AIT Test Run Input Handler"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TestInputGroupCode: Code[100];
        TestInputCode: Code[100];

    internal procedure SetInput(InputGroupCode: Code[100]; InputCode: Code[100])
    begin
        TestInputGroupCode := InputGroupCode;
        TestInputCode := InputCode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIT Test Run Iteration", 'OnBeforeRunIteration', '', false, false)]
    local procedure OnBeforeRunIteration(var AITTestMethodLine: Record "AIT Test Method Line"; var AITTestSuite: Record "AIT Test Suite"; var RunAllTests: Boolean; var UpdateTestSuite: Boolean)
    begin
        RunAllTests := false;
        UpdateTestSuite := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIT Test Run Iteration", 'OnBeforeRunTestMethodLine', '', false, false)]
    local procedure OnBeforeRunTestMethodLine(var TestMethodLine: Record "Test Method Line")
    var
        TestInput: Codeunit "Test Input";
    begin
        TestMethodLine.SetRange("Data Input Group Code", TestInputGroupCode);
        TestMethodLine.SetRange("Data Input", TestInputCode);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Function);

        // Load the test input now, while still running under full permissions. The data-driven test framework
        // otherwise reads it from inside the test method's TestPermissions scope, which fails for any test that
        // declares a TestPermissions value other than Disabled (bug 636024).
        TestInput.PreloadTestInput(TestInputGroupCode, TestInputCode);
    end;

}
