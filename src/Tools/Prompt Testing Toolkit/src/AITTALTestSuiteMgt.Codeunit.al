// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;
using System.Reflection;

codeunit 149037 "AITT AL Test Suite Mgt"
{
    Permissions = tabledata "Test Method Line" = rmid,
                  tabledata "AL Test Suite" = rmid;

    internal procedure AssistEditTestRunner(var BCCTHeader: Record "BCCT Header")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        SelectTestRunner: Page "Select TestRunner";
    begin
        SelectTestRunner.LookupMode := true;
        if SelectTestRunner.RunModal() = ACTION::LookupOK then begin
            SelectTestRunner.GetRecord(AllObjWithCaption);
            BCCTHeader.Validate("Test Runner Id", AllObjWithCaption."Object ID");
            BCCTHeader.Modify(true);
        end;
    end;

    internal procedure UpdateALTestSuite(var BCCTLine: Record "BCCT Line")
    begin
        this.GetOrCreateALTestSuite(BCCTLine);
        this.RemoveTestMethods(BCCTLine);
        this.ExpandCodeunit(BCCTLine);
    end;

    internal procedure CreateALTestSuite(var BCCTHeader: Record "BCCT Header")
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        if ALTestSuite.Get(BCCTHeader.Code) then
            ALTestSuite.Delete(true);

        ALTestSuite.Name := BCCTHeader.Code;
        ALTestSuite."Test Runner Id" := BCCTHeader."Test Runner Id";
        ALTestSuite.Insert(true);
    end;

    internal procedure ExpandCodeunit(var BCCTLine: Record "BCCT Line")
    var
        TestInupt: Record "Test Input";
    begin
        TestInupt.SetRange("Test Input Group Code", BCCTLine.GetTestInputCode());
        TestInupt.ReadIsolation := TestInupt.ReadIsolation::ReadUncommitted;
        if not TestInupt.FindSet() then
            exit;

        repeat
            this.ExpandCodeunit(BCCTLine, TestInupt);
        until TestInupt.Next() = 0;
    end;

    internal procedure ExpandCodeunit(var BCCTLine: Record "BCCT Line"; var TestInput: Record "Test Input")
    var
        TempTestMethodLine: Record "Test Method Line" temporary;
        ALTestSuite: Record "AL Test Suite";
        TestInputsManagement: Codeunit "Test Inputs Management";
    begin
        ALTestSuite := this.GetOrCreateALTestSuite(BCCTLine);

        TempTestMethodLine."Line Type" := TempTestMethodLine."Line Type"::Codeunit;
        TempTestMethodLine."Test Codeunit" := BCCTLine."Codeunit ID";
        TempTestMethodLine."Test Suite" := BCCTLine."AL Test Suite";
        TempTestMethodLine."Data Input Group Code" := TestInput."Test Input Group Code";
        TempTestMethodLine."Data Input" := TestInput.Code;
        TempTestMethodLine.Insert();

        TestInputsManagement.InsertTestMethodLines(TempTestMethodLine, ALTestSuite);
    end;

    internal procedure RemoveTestMethods(var BCCTLine: Record "BCCT Line")
    begin
        this.RemoveTestMethods(BCCTLine, 0, '');
    end;

    internal procedure RemoveTestMethods(var BCCTLine: Record "BCCT Line"; CodeunitID: Integer; DataInputName: Text[250])
    var
        TestMethodLine: Record "Test Method Line";
    begin
        if CodeunitID > 1 then
            TestMethodLine.SetRange("Test Codeunit", CodeunitID);

        if DataInputName <> '' then
            TestMethodLine.SetRange("Data Input", DataInputName);

        TestMethodLine.ReadIsolation := TestMethodLine.ReadIsolation::ReadUncommitted;
        if TestMethodLine.IsEmpty() then
            exit;

        TestMethodLine.DeleteAll();
        this.RemoveEmptyCodeunitTestLines(this.GetOrCreateALTestSuite(BCCTLine));
    end;

    internal procedure RemoveEmptyCodeunitTestLines(ALTestSuite: Record "AL Test Suite")
    var
        TestMethodLine: Record "Test Method Line";
        FunctionTestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        TestMethodLine.ReadIsolation := TestMethodLine.ReadIsolation::ReadUncommitted;

        if not TestMethodLine.FindSet() then
            exit;

        repeat
            FunctionTestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
            FunctionTestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");
            FunctionTestMethodLine.SetRange("Line Type", FunctionTestMethodLine."Line Type"::Function);
            FunctionTestMethodLine.ReadIsolation := FunctionTestMethodLine.ReadIsolation::ReadUncommitted;
            if FunctionTestMethodLine.IsEmpty() then
                TestMethodLine.Delete();
        until TestMethodLine.Next() = 0;
    end;

    internal procedure GetOrCreateALTestSuite(var BCCTLine: Record "BCCT Line"): Record "AL Test Suite"
    var
        BCCTHeader: Record "BCCT Header";
        ALTestSuite: Record "AL Test Suite";
    begin
        if BCCTLine."AL Test Suite" <> '' then begin
            ALTestSuite.SetFilter(Name, BCCTLine."AL Test Suite");
            if ALTestSuite.FindFirst() then
                exit(ALTestSuite);
        end;

        if BCCTLine."AL Test Suite" = '' then begin
            BCCTLine."AL Test Suite" := this.GetUniqueAITTestSuiteCode();
            BCCTLine.Modify();
        end;

        ALTestSuite.Name := BCCTLine."AL Test Suite";
        ALTestSuite.Description := CopyStr(BCCTLine.Description, 1, MaxStrLen(ALTestSuite.Description));
        BCCTHeader.ReadIsolation := IsolationLevel::ReadUncommitted;
        if BCCTHeader.Get(BCCTLine."BCCT Code") then
            ALTestSuite."Test Runner Id" := BCCTHeader."Test Runner Id";

        ALTestSuite.Insert(true);
        exit(ALTestSuite);
    end;

    local procedure GetUniqueAITTestSuiteCode(): Code[10]
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        ALTestSuite.SetFilter(Name, this.AITTestSuitePrefixLbl + '*');
        if not ALTestSuite.FindLast() then
            exit(this.AITTestSuitePrefixLbl + '000001');

        exit(IncStr(ALTestSuite.Name))
    end;

    var
        AITTestSuitePrefixLbl: Label 'AIT-', Locked = true;
}