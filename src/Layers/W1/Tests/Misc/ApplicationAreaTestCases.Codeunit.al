// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139094 "Application Area Test Cases" implements ITestDataSource, ITestContext
{
    procedure ListTestCases(DataSetIdentifier: Text; Context: DataSourceContext): List of [Text]
    var
        Cases: List of [Text];
    begin
        Cases.Add('First');
        Cases.Add('Second');
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; Context: DataSourceContext): Interface ITestContext
    var
        CaseContext: Codeunit "Application Area Test Cases";
    begin
        exit(CaseContext);
    end;
}
