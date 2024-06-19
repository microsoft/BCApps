// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130460 "Test Input"
{
    SingleInstance = true;
    Permissions = tabledata "Test Input" = RMID;
    // TODO: Access Internal?

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure BeforeTestMethodRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var CurrentTestMethodLine: Record "Test Method Line")
    begin
        this.InitializeTestInputsBeforeTestMethodRun(CodeunitID, CodeunitName, FunctionName, FunctionTestPermissions, CurrentTestMethodLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterRunTestSuite', '', false, false)]
    local procedure AfterTestSuite()
    begin
        this.ClearGlobals();
    end;

    internal procedure InitializeTestInputsBeforeTestMethodRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var CurrentTestMethodLine: Record "Test Method Line")
    begin
        if CurrentTestMethodLine."Data Input" = '' then
            exit;

        if (CurrentTestMethodLine."Data Input" = this.DataPerTest.Code) and (CurrentTestMethodLine."Data Input Group Code" = this.DataPerTest."Test Input Group Code") then
            exit;

        this.DataPerTest.Get(CurrentTestMethodLine."Data Input Group Code", CurrentTestMethodLine."Data Input");

        this.DataPerTestTestInput.Initialize(this.DataPerTest.GetInput(this.DataPerTest));
    end;

    local procedure ClearGlobals()
    begin
        Clear(this.DataPerTest);
        Clear(this.DataPerTestTestInput);
    end;

    procedure GetTestInputName(): Text
    begin
        exit(this.DataPerTest.GetTestInputDisplayName(this.DataPerTest."Test Input Group Code", this.DataPerTest.Code));
    end;

    procedure GetTestInput(ElementName: Text): Codeunit "Test Input Json"
    var
        TestInputJson: Codeunit "Test Input Json";
        ElementExists: Boolean;
    begin
        TestInputJson := this.DataPerTestTestInput.ElementExists(ElementName, ElementExists);
        if ElementExists then
            exit(TestInputJson);
    end;

    procedure GetTestInput(): Codeunit "Test Input Json"
    begin
        exit(this.DataPerTestTestInput);
    end;

    procedure GetTestInputValue(): Text
    begin
        exit(this.DataPerTest.GetInput(this.DataPerTest));
    end;

    var
        DataPerTest: Record "Test Input";
        DataPerTestTestInput: Codeunit "Test Input Json";
}