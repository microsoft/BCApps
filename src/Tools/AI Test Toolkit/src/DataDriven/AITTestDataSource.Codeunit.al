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
    var
        NoDatasetErr: Label 'No dataset could be resolved for the data-driven test identifier ''%1''. Ensure the Test Input Group exists.', Comment = '%1 = the dataset identifier from the [TestDataSource] attribute';
        EmptyDatasetErr: Label 'The dataset ''%1'' for the data-driven test resolved to zero rows. A data-driven test must have at least one case.', Comment = '%1 = the resolved Test Input Group code';

    /// <summary>
    /// Enumerates the identifiers (dataset row codes) of every case for the dataset identified by
    /// <paramref name="DataSetIdentifier"/>. Returned up front so the runtime knows the full set of cases.
    /// </summary>
    /// <param name="DataSetIdentifier">The dataset id from the attribute: a Test Input Group code or group name.</param>
    /// <param name="context">Metadata about the calling test (codeunit id, app id).</param>
    procedure ListTestCases(DataSetIdentifier: Text; context: DataSourceContext): List of [Text]
    var
        TestInputDataSourceMgt: Codeunit "Test Input Data Source Mgt.";
        Ids: List of [Text];
        GroupCode: Code[100];
    begin
        GroupCode := ResolveGroupCode(DataSetIdentifier);
        if GroupCode = '' then
            Error(NoDatasetErr, DataSetIdentifier);

        Ids := TestInputDataSourceMgt.ListTestCaseIdentifiers(GroupCode);

        if Ids.Count() = 0 then
            Error(EmptyDatasetErr, GroupCode);

        exit(Ids);
    end;

    /// <summary>
    /// Materializes the context for a single dataset row on demand. Called only for cases that actually run.
    /// </summary>
    /// <param name="DataSetIdentifier">The dataset id from the attribute.</param>
    /// <param name="TestCaseIndex">The 1-based position of the case in the <see cref="ListTestCases"/> result.</param>
    /// <param name="TestCaseIdentifier">The row code of the case to materialize.</param>
    /// <param name="context">Metadata about the calling test (codeunit id, app id).</param>
    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; context: DataSourceContext): interface ITestContext
    var
        DDTestContext: Codeunit "AIT DD Test Context";
        TestDataSourceContext: Codeunit "Test Data Source Context";
        TestInput: Codeunit "Test Input";
        GroupCode: Code[100];
        RowCode: Code[100];
    begin
        GroupCode := ResolveGroupCode(DataSetIdentifier);
        if GroupCode = '' then
            Error(NoDatasetErr, DataSetIdentifier);

        RowCode := CopyStr(TestCaseIdentifier, 1, MaxStrLen(RowCode));
        DDTestContext.Init(GroupCode, RowCode);

        // Preload the Test Input single-instance cache before the body runs. Existing evals and helper libraries
        // can therefore keep using the app-level AIT Test Context codeunit without threading the injected context
        // parameter through every call.
        TestInput.PreloadTestInput(GroupCode, RowCode);
        TestDataSourceContext.SetCurrent(GroupCode, RowCode);

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
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
        TestInputDataSourceMgt: Codeunit "Test Input Data Source Mgt.";
        RunContextDataset: Code[100];
    begin
        AITTestRunIteration.GetAITTestMethodLine(AITTestMethodLine);
        if AITTestMethodLine."Test Suite Code" <> '' then begin
            RunContextDataset := AITTestMethodLine.GetTestInputCode();
            if RunContextDataset <> '' then
                exit(RunContextDataset);
        end;

        exit(TestInputDataSourceMgt.ResolveGroupCode(DataSetIdentifier));
    end;
}
