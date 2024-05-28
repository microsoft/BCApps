// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.TestTools.TestRunner;

codeunit 149037 "AITT AL Test Suite Mgt"
{
    Permissions = tabledata "Test Method Line" = rmid,
                  tabledata "AL Test Suite" = rmid;

    internal procedure ExpandCodeunit(CodeunitID: Integer; var BCCTHeader: Record "BCCT Header")
    var
        TestInupt: Record "Test Input";
    begin
        TestInupt.SetRange("Test Suite", BCCTHeader.Code);
        TestInupt.ReadIsolation := TestInupt.ReadIsolation::ReadUncommitted;
        if not TestInupt.FindSet() then
            exit;

        repeat
            ExpandCodeunit(CodeunitID, BCCTHeader, TestInupt.Name);
        until TestInupt.Next() = 0;
    end;

    internal procedure ExpandCodeunit(CodeunitID: Integer; var BCCTHeader: Record "BCCT Header"; DataInputName: Text[250])
    var
        TempTestMethodLine: Record "Test Method Line" temporary;
        ALTestSuite: Record "AL Test Suite";
        TestInputsManagement: Codeunit "Test Inputs Management";
    begin
        GetOrCreateALTestSuiteExist(BCCTHeader);

        TempTestMethodLine."Line Type" := TempTestMethodLine."Line Type"::Codeunit;
        TempTestMethodLine."Test Codeunit" := CodeunitID;
        TempTestMethodLine."Test Suite" := BCCTHeader.Code;
        TempTestMethodLine."Data Input" := DataInputName;
        TempTestMethodLine.Insert();

        TestInputsManagement.InsertTestMethodLines(TempTestMethodLine, ALTestSuite);
    end;

    internal procedure RemoveCodeunit(CodeunitID: Integer; var BCCTHeader: Record "BCCT Header")
    var
        TestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine.SetRange("Test Codeunit", CodeunitID);
        TestMethodLine.ReadIsolation := TestMethodLine.ReadIsolation::ReadUncommitted;
        if TestMethodLine.IsEmpty() then
            exit;

        TestMethodLine.DeleteAll();
        RemoveEmptyCodeunitTestLines(GetOrCreateALTestSuiteExist(BCCTHeader));
    end;

    internal procedure RemoveDataInput(var BCCTHeader: Record "BCCT Header"; CodeunitID: Integer; DataInputName: Text[250])
    var
        TestMethodLine: Record "Test Method Line";
    begin
        if CodeunitID > 1 then
            TestMethodLine.SetRange("Test Codeunit", CodeunitID);

        TestMethodLine.SetRange("Data Input", DataInputName);
        TestMethodLine.ReadIsolation := TestMethodLine.ReadIsolation::ReadUncommitted;
        if TestMethodLine.IsEmpty() then
            exit;

        TestMethodLine.DeleteAll();
        RemoveEmptyCodeunitTestLines(GetOrCreateALTestSuiteExist(BCCTHeader));
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

    internal procedure GetOrCreateALTestSuiteExist(BCCTHeader: Record "BCCT Header"): Record "AL Test Suite"
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        if ALTestSuite.Get(BCCTHeader.Code) then
            exit(ALTestSuite);

        ALTestSuite.Name := BCCTHeader.Code;
        ALTestSuite.Description := BCCTHeader.Description;
        ALTestSuite.Insert(true);
        exit(ALTestSuite);
    end;
}