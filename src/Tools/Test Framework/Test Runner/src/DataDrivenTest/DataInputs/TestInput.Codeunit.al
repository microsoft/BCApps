// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130460 "Test Input"
{
    SingleInstance = true;
    Permissions = tabledata "Test Input" = RMID;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeCodeunitRun', '', false, false)]
    local procedure BeforeCodeunitRun(var TestMethodLine: Record "Test Method Line")
    begin
        InitializeTestInputsBeforeSuiteRun(TestMethodLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure BeforeTestMethodRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var CurrentTestMethodLine: Record "Test Method Line")
    begin
        InitializeTestInputsBeforeTestMethodRun(CodeunitID, CodeunitName, FunctionName, FunctionTestPermissions, CurrentTestMethodLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterRunTestSuite', '', false, false)]
    local procedure AfterTestSuite()
    begin
        ClearGlobals();
    end;

    internal procedure InitializeTestInputsBeforeTestMethodRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var CurrentTestMethodLine: Record "Test Method Line")
    begin
        if CurrentTestMethodLine."Data Input" = '' then
            exit;

        if CurrentTestMethodLine."Data Input" = DataPerTest.Name then
            exit;

        DataPerTest.Get(CurrentTestMethodLine."Test Suite", CurrentTestMethodLine."Data Input");

        DataPerTestTestInput.Initialize(DataPerTest.GetInput(DataPerTest));
    end;

    internal procedure InitializeTestInputsBeforeSuiteRun(var TestMethodLine: Record "Test Method Line")
    begin
        ClearGlobals();
        if TestMethodLine."Data Input" = '' then
            exit;

        DataPerSuite.Get(TestMethodLine."Test Suite", TestMethodLine."Data Input");

        DataPerSuiteTestInput.Initialize(DataPerSuite.GetInput(DataPerSuite));
    end;

    local procedure ClearGlobals()
    begin
        Clear(DataPerSuite);
        Clear(DataPerSuiteTestInput);
        Clear(DataPerTest);
        Clear(DataPerTestTestInput);
    end;

    procedure GetTestInputName(): Text
    begin
        if DataPerTest.Name <> '' then
            exit(DataPerTest.Name);

        exit(DataPerSuite.Name);
    end;

    procedure GetTestInput(ElementName: Text): Codeunit "Test Input Json"
    var
        TestInputJson: Codeunit "Test Input Json";
        ElementExists: Boolean;
    begin
        if DataPerTest.Name <> '' then begin
            TestInputJson := DataPerTestTestInput.ElementExists(ElementName, ElementExists);
            if ElementExists then
                exit(TestInputJson)
        end;

        TestInputJson := DataPerSuiteTestInput.Element(ElementName);
        exit(TestInputJson);
    end;

    var
        DataPerSuite: Record "Test Input";
        DataPerSuiteTestInput: Codeunit "Test Input Json";

        DataPerTest: Record "Test Input";
        DataPerTestTestInput: Codeunit "Test Input Json";
}