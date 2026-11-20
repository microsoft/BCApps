// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139206 "Library Random Test Cases" implements System.Test.ITestDataSource, System.Test.ITestContext
{
    SingleInstance = true;

    var
        First: Integer;
        Second: Integer;

    procedure ListTestCases(DataSetIdentifier: Text; Context: DataSourceContext): List of [Text]
    var
        Cases: List of [Text];
    begin
        Cases.Add('First');
        Cases.Add('Second');
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; Context: DataSourceContext): Interface System.Test.ITestContext
    var
        LibraryRandom: Codeunit "Library - Random";
        CaseContext: Codeunit "Library Random Test Cases";
    begin
        if DataSetIdentifier = 'Explicit' then
            LibraryRandom.SetSeed(91);
        First := Random(100000);
        if DataSetIdentifier = 'Default' then
            Second := LibraryRandom.RandInt(100000);
        exit(CaseContext);
    end;

    procedure FirstValue(): Integer
    begin
        exit(First);
    end;

    procedure SecondValue(): Integer
    begin
        exit(Second);
    end;
}
