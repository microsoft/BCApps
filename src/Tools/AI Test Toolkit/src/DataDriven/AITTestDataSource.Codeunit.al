// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Test;
using System.TestTools.TestRunner;

/// <summary>
/// Shared data source for language-first data-driven AI evals. A single instance of this codeunit is referenced
/// by every consuming app via <c>[TestDataSource(Codeunit::"AIT Test Data Source", '&lt;dataset&gt;')]</c>; there is
/// no need for a per-app provider. It resolves the dataset from the shared <c>Test Input Group</c>/<c>Test Input</c>
/// tables (imported from each app's dataset resource) and returns one <see cref="ITestContext"/> per data row.
/// </summary>
codeunit 149038 "AIT Test Data Source" implements ITestDataSource
{
    /// <summary>
    /// Returns one context per row of the dataset identified by <paramref name="DataSetIdentifier"/>.
    /// </summary>
    /// <param name="DataSetIdentifier">The dataset id from the attribute: a Test Input Group code or group name.</param>
    /// <param name="context">Metadata about the calling test (codeunit id, app id).</param>
    procedure GetDataRows(DataSetIdentifier: Text; context: DataSourceContext): List of [Interface ITestContext]
    var
        TestInput: Record "Test Input";
        Rows: List of [Interface ITestContext];
        GroupCode: Code[100];
    begin
        GroupCode := ResolveGroupCode(DataSetIdentifier);
        if GroupCode = '' then
            exit(Rows);

        TestInput.SetRange("Test Input Group Code", GroupCode);
        if TestInput.FindSet() then
            repeat
                Rows.Add(CreateContext(GroupCode, TestInput.Code));
            until TestInput.Next() = 0;

        exit(Rows);
    end;

    local procedure CreateContext(GroupCode: Code[100]; RowCode: Code[100]): Interface ITestContext
    var
        DDTestContext: Codeunit "AIT DD Test Context";
    begin
        DDTestContext.Init(GroupCode, RowCode);
        exit(DDTestContext);
    end;

    /// <summary>Resolves a dataset identifier to a Test Input Group code.</summary>
    /// <remarks>
    /// When running under an AIT test suite, the dataset configured on the current suite line takes precedence
    /// (so one [TestDataSource] method can run against multiple datasets across suite lines); when run
    /// standalone, the attribute's <paramref name="DataSetIdentifier"/> literal is used (by code, then by group name).
    /// </remarks>
    local procedure ResolveGroupCode(DataSetIdentifier: Text): Code[100]
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        TestInputGroup: Record "Test Input Group";
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
        RunContextDataset: Code[100];
    begin
        AITTestRunIteration.GetAITTestMethodLine(AITTestMethodLine);
        if AITTestMethodLine."Test Suite Code" <> '' then begin
            RunContextDataset := AITTestMethodLine.GetTestInputCode();
            if RunContextDataset <> '' then
                exit(RunContextDataset);
        end;

        if TestInputGroup.Get(CopyStr(DataSetIdentifier, 1, MaxStrLen(TestInputGroup.Code))) then
            exit(TestInputGroup.Code);

        TestInputGroup.SetRange("Group Name", CopyStr(DataSetIdentifier, 1, MaxStrLen(TestInputGroup."Group Name")));
        if TestInputGroup.FindFirst() then
            exit(TestInputGroup.Code);

        exit('');
    end;
}
