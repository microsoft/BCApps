// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

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

    internal procedure ExpandCodeunit(BCCTLine: Record "BCCT Line")
    var
        TestInupt: Record "Test Input";
    begin
        TestInupt.SetRange("Test Suite", BCCTLine."BCCT Code");
        TestInupt.ReadIsolation := TestInupt.ReadIsolation::ReadUncommitted;
        if not TestInupt.FindSet() then
            exit;

        repeat
            ExpandCodeunit(BCCTLine, TestInupt.Name);
        until TestInupt.Next() = 0;
    end;

    internal procedure ExpandCodeunit(BCCTLine: Record "BCCT Line"; DataInputName: Text[250])
    var
        TempTestMethodLine: Record "Test Method Line" temporary;
        ALTestSuite: Record "AL Test Suite";
        BCCTHeader: Record "BCCT Header";
        TestInputsManagement: Codeunit "Test Inputs Management";
    begin
        BCCTHeader.Get(BCCTLine."BCCT Code");
        ALTestSuite := GetOrCreateALTestSuite(BCCTHeader);

        TempTestMethodLine."Line Type" := TempTestMethodLine."Line Type"::Codeunit;
        TempTestMethodLine."Test Codeunit" := BCCTLine."Codeunit ID";
        TempTestMethodLine."Test Suite" := BCCTHeader.Code;
        TempTestMethodLine."Data Input" := DataInputName;
        TempTestMethodLine.Insert();

        TestInputsManagement.InsertTestMethodLines(TempTestMethodLine, ALTestSuite);
    end;

    internal procedure RemoveTestMethods(var BCCTHeader: Record "BCCT Header")
    begin
        RemoveTestMethods(BCCTHeader, 0, '');
    end;

    internal procedure RemoveTestMethods(var BCCTHeader: Record "BCCT Header"; CodeunitID: Integer; DataInputName: Text[250])
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
        RemoveEmptyCodeunitTestLines(GetOrCreateALTestSuite(BCCTHeader));
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

    internal procedure GetOrCreateALTestSuite(BCCTHeader: Record "BCCT Header"): Record "AL Test Suite"
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        if ALTestSuite.Get(BCCTHeader.Code) then
            exit(ALTestSuite);

        ALTestSuite.Name := BCCTHeader.Code;
        ALTestSuite.Description := BCCTHeader.Description;
        ALTestSuite."Test Runner Id" := BCCTHeader."Test Runner Id";
        ALTestSuite.Insert(true);
        exit(ALTestSuite);
    end;
}