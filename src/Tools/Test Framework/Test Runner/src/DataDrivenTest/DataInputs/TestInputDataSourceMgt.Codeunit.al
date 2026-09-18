// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Provides generic dataset lookup and case enumeration for data-source providers backed by
/// the Test Runner's Test Input Group and Test Input tables.
/// </summary>
codeunit 130466 "Test Input Data Source Mgt."
{
    Access = Public;

    procedure ResolveGroupCode(DataSetIdentifier: Text): Code[100]
    var
        TestInputGroup: Record "Test Input Group";
    begin
        if TestInputGroup.Get(CopyStr(DataSetIdentifier, 1, MaxStrLen(TestInputGroup.Code))) then
            exit(TestInputGroup.Code);

        TestInputGroup.SetRange("Group Name", CopyStr(DataSetIdentifier, 1, MaxStrLen(TestInputGroup."Group Name")));
        if TestInputGroup.FindFirst() then
            exit(TestInputGroup.Code);

        exit('');
    end;

    procedure ListTestCaseIdentifiers(GroupCode: Code[100]): List of [Text]
    var
        TestInput: Record "Test Input";
        TestCaseIdentifiers: List of [Text];
    begin
        TestInput.SetRange("Test Input Group Code", GroupCode);
        if TestInput.FindSet() then
            repeat
                TestCaseIdentifiers.Add(TestInput.Code);
            until TestInput.Next() = 0;

        exit(TestCaseIdentifiers);
    end;
}
