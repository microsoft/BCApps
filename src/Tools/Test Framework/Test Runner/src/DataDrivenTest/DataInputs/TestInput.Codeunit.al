// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130460 "Test Input"
{
    SingleInstance = true;
    Permissions = tabledata "Test Input" = RMID, tabledata "Test Method Line" = RMID;

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
        LoadTestInput(CurrentTestMethodLine."Data Input Group Code", CurrentTestMethodLine."Data Input");
    end;

    /// <summary>
    /// Pre-loads the test input into the single-instance globals before the test method runs.
    /// </summary>
    /// <param name="TestInputGroupCode">The test input group code to load.</param>
    /// <param name="TestInputCode">The test input code to load.</param>
    /// <remarks>
    /// The data-driven test framework reads the "Test Input" table from a subscriber to OnBeforeTestMethodRun,
    /// which the platform raises inside the test method's TestPermissions scope. When a test declares a
    /// TestPermissions value other than Disabled, the platform overrides the effective permissions and the
    /// IndirectRead on the "Test Input" table fails. Calling this from a context that still runs under full
    /// permissions (before the test runner is invoked) caches the input so the later read inside the restricted
    /// scope is a no-op.
    /// </remarks>
    procedure PreloadTestInput(TestInputGroupCode: Code[100]; TestInputCode: Code[100])
    begin
        LoadTestInput(TestInputGroupCode, TestInputCode);
    end;

    local procedure LoadTestInput(TestInputGroupCode: Code[100]; TestInputCode: Code[100])
    begin
        if TestInputCode = '' then
            exit;

        if (TestInputCode = DataPerTest.Code) and (TestInputGroupCode = DataPerTest."Test Input Group Code") then
            exit;

        DataPerTest.Get(TestInputGroupCode, TestInputCode);

        DataPerTestTestInput.Initialize(DataPerTest.GetInput(DataPerTest));
    end;

    local procedure ClearGlobals()
    begin
        Clear(DataPerTest);
        Clear(DataPerTestTestInput);
    end;

    procedure GetTestInputName(): Text
    begin
        exit(DataPerTest.GetTestInputDisplayName(DataPerTest."Test Input Group Code", DataPerTest.Code));
    end;

    procedure GetTestInput(ElementName: Text): Codeunit "Test Input Json"
    var
        TestInputJson: Codeunit "Test Input Json";
        ElementExists: Boolean;
    begin
        TestInputJson := DataPerTestTestInput.ElementExists(ElementName, ElementExists);
        if ElementExists then
            exit(TestInputJson);
    end;

    procedure GetTestInput(): Codeunit "Test Input Json"
    begin
        exit(DataPerTestTestInput);
    end;

    procedure GetTestInputValue(): Text
    begin
        exit(DataPerTest.GetInput(DataPerTest));
    end;

    procedure GetTestInputByCode(GroupCode: Code[100]; InputCode: Code[100]): Codeunit "Test Input Json"
    var
        TestInputRec: Record "Test Input";
        TestInputJson: Codeunit "Test Input Json";
        InputContent: Text;
    begin
        if not TestInputRec.Get(GroupCode, InputCode) then
            exit(TestInputJson);

        InputContent := TestInputRec.GetInput(TestInputRec);
        if InputContent <> '' then
            TestInputJson.Initialize(InputContent);

        exit(TestInputJson);
    end;

    var
        DataPerTest: Record "Test Input";
        DataPerTestTestInput: Codeunit "Test Input Json";
}