// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries.Test;

using Microsoft.Foundation.NoSeries;
using System.TestLibraries.Utilities;
using System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

codeunit 133689 "No. Series Copilot Accu. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = AITest;

    var
        Assert: codeunit "Library Assert";
        AITTestContext: codeunit "AIT Test Context";
        NoSeriesCopilotTestLib: codeunit "Library - No. Series Copilot";

    [Test]
    procedure NoSeriesPositiveTests();
    var
        TempNoSeriesGeneration: Record "No. Series Generation";
        TempNoSeriesGenerationDetail: Record "No. Series Generation Detail";
        TestInputJsonQuery: Codeunit "Test Input Json";
        TestInputJsonAnswer: Codeunit "Test Input Json";
        ExpectedNumberJson: Codeunit "Test Input Json";
        Found: Boolean;
    begin
        TestInputJsonQuery := AITTestContext.GetQuery();
        NoSeriesCopilotTestLib.Generate(TempNoSeriesGeneration, TempNoSeriesGenerationDetail, TestInputJsonQuery.ValueAsText());

        TestInputJsonAnswer := AITTestContext.GetExpectedData();

        ExpectedNumberJson := TestInputJsonAnswer.ElementAt(0).ElementExists('expected_number', Found);
        if not Found then
            Assert.Fail('Expected "expected_number" field not found in the test input JSON answer.');

        Assert.AreNearlyEqual(ExpectedNumberJson.ValueAsInteger(), TempNoSeriesGenerationDetail.Count, 1.0, 'No. Series Copilot failed to generate the expected number of No. Series.');
        Assert.IsTrue(TempNoSeriesGenerationDetail.Count > 0, 'No. Series Copilot did not generate any No. Series, but expected some.');

        AITTestContext.SetTestOutput('Test succeeded. ' + Format(TempNoSeriesGenerationDetail.Count) + ' new No. Series generated based on the input.');
    end;
}