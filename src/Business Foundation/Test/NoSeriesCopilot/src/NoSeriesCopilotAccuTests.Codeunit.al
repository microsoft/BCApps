// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries.Test;

using Microsoft.Foundation.NoSeries;
using System.TestLibraries.Utilities;
using System.TestTools.TestRunner;
using System.TestTools.AITestToolkit;

codeunit 134540 "No. Series Copilot Accu. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    
    var
        Assert: codeunit "Library Assert";
        AITTestContext: codeunit "AIT Test Context";
        NoSeriesCopilotTestLib: codeunit "Library - No. Series Copilot";

    [Test]
    procedure NoSeriesPositiveTests();
    var
        NoSeriesGeneration: Record "No. Series Generation";
        NoSeriesGenerationDetail: Record "No. Series Generation Detail";
        TestInputJsonQuestion: Codeunit "Test Input Json";
        TestInputJsonAnswer: Codeunit "Test Input Json";
    begin
        TestInputJsonQuestion := AITTestContext.GetQuestion();      
        NoSeriesCopilotTestLib.Generate(NoSeriesGeneration, NoSeriesGenerationDetail, TestInputJsonQuestion.ValueAsText());
        
        TestInputJsonAnswer := AITTestContext.GetExpectedData();
        Assert.AreEqual(TestInputJsonAnswer.ValueAsInteger(), NoSeriesGenerationDetail.Count, 'No. Series Copilot failed to generate the expected number of No. Series.');
        AITTestContext.SetTestOutput('Test succeeded. ' + Format(NoSeriesGenerationDetail.Count) + ' new No. Series generated based on the input.');
    end;
}