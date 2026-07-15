// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Test;
using System.TestTools.TestRunner;

/// <summary>
/// Per-case context for a language-first data-driven AI eval. Extends the platform <see cref="ITestContext"/>
/// so it can be used as the parameter of a [TestDataSource] test method, while exposing the same input/output
/// surface as the classic <c>AIT Test Context</c> codeunit. Instances are produced by the shared
/// <c>AIT Test Data Source</c> provider, one per dataset row.
/// </summary>
interface "AIT Test Case Context" extends ITestContext
{
    /// <summary>Returns the full input for the current data row.</summary>
    procedure GetInput(): Codeunit "Test Input Json";

    /// <summary>Returns the 'query' (or legacy 'question') element for the current data row.</summary>
    procedure GetQuery(): Codeunit "Test Input Json";

    /// <summary>Returns the 'context' element for the current data row.</summary>
    procedure GetContext(): Codeunit "Test Input Json";

    /// <summary>Returns the 'ground_truth' element for the current data row.</summary>
    procedure GetGroundTruth(): Codeunit "Test Input Json";

    /// <summary>Returns the 'expected_data' element for the current data row.</summary>
    procedure GetExpectedData(): Codeunit "Test Input Json";

    /// <summary>Returns the 'turn_setup' element for the current turn.</summary>
    procedure GetTurnSetup(): Codeunit "Test Input Json";

    /// <summary>Returns the legacy 'test_setup' element for the current data row.</summary>
    procedure GetTestSetup(): Codeunit "Test Input Json";

    /// <summary>Returns the 'continue_on_failure' flag for the current turn.</summary>
    procedure GetCanContinueOnFailure(): Boolean;

    /// <summary>Sets the answer text as the output for the current iteration.</summary>
    procedure SetTestOutput(TestOutputText: Text);

    /// <summary>Sets context/question/answer as the output for the current iteration.</summary>
    procedure SetTestOutput(Context: Text; Question: Text; Answer: Text);

    /// <summary>Sets the query and response for a single-turn evaluation.</summary>
    procedure SetQueryResponse(Query: Text; Response: Text);

    /// <summary>Sets the answer for a question-and-answer evaluation.</summary>
    procedure SetAnswerForQnAEvaluation(Answer: Text);

    /// <summary>Adds a message to a multi-turn output.</summary>
    procedure AddMessage(Content: Text; Role: Text);

    /// <summary>Sets the test metric for the output dataset.</summary>
    procedure SetTestMetric(TestMetric: Text);

    /// <summary>Sets the accuracy (0..1) of the eval.</summary>
    procedure SetAccuracy(Accuracy: Decimal);

    /// <summary>Adds externally consumed tokens to the current method line.</summary>
    procedure SetTokenConsumption(TokensUsed: Integer);

    /// <summary>Advances to the next turn of a multi-turn eval.</summary>
    procedure NextTurn(): Boolean;

    /// <summary>Gets the current turn number.</summary>
    procedure GetCurrentTurn(): Integer;
}
