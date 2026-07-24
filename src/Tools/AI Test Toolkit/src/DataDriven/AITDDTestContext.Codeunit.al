// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

/// <summary>
/// Concrete per-case context produced by the <c>AIT Test Data Source</c> provider. It carries the identity of
/// one dataset row (its Test Input Group + Code) and, on each access, preloads that row into the data-driven
/// framework's single-instance cache before delegating to the classic <c>AIT Test Context</c> API — so existing
/// eval logic keeps working unchanged while the platform (not the AIT runner) drives the per-case fan-out.
/// </summary>
codeunit 149040 "AIT DD Test Context" implements "AIT Test Case Context"
{
    Access = Internal;

    var
        AITTestContext: Codeunit "AIT Test Context";
        InputGroupCode: Code[100];
        InputCode: Code[100];

    /// <summary>Binds this context to a specific dataset row.</summary>
    /// <param name="GroupCode">The Test Input Group code (dataset).</param>
    /// <param name="RowCode">The Test Input code (row / case).</param>
    procedure Init(GroupCode: Code[100]; RowCode: Code[100])
    begin
        InputGroupCode := GroupCode;
        InputCode := RowCode;
    end;

    /// <summary>Loads this case's data row into the data-driven single-instance cache.</summary>
    local procedure Preload()
    var
        TestInput: Codeunit "Test Input";
        DDCurrentCase: Codeunit "AIT DD Current Case";
    begin
        TestInput.PreloadTestInput(InputGroupCode, InputCode);
        DDCurrentCase.SetCurrent(InputGroupCode, InputCode);
    end;

    procedure Identifier(): Text
    begin
        exit(InputCode);
    end;

    procedure GetInput(): Codeunit "Test Input Json"
    begin
        Preload();
        exit(AITTestContext.GetInput());
    end;

    procedure GetQuery(): Codeunit "Test Input Json"
    begin
        Preload();
        exit(AITTestContext.GetQuery());
    end;

    procedure GetContext(): Codeunit "Test Input Json"
    begin
        Preload();
        exit(AITTestContext.GetContext());
    end;

    procedure GetGroundTruth(): Codeunit "Test Input Json"
    begin
        Preload();
        exit(AITTestContext.GetGroundTruth());
    end;

    procedure GetExpectedData(): Codeunit "Test Input Json"
    begin
        Preload();
        exit(AITTestContext.GetExpectedData());
    end;

    procedure GetTurnSetup(): Codeunit "Test Input Json"
    begin
        Preload();
        exit(AITTestContext.GetTurnSetup());
    end;

    procedure GetTestSetup(): Codeunit "Test Input Json"
    begin
        Preload();
        exit(AITTestContext.GetTestSetup());
    end;

    procedure GetCanContinueOnFailure(): Boolean
    begin
        Preload();
        exit(AITTestContext.GetCanContinueOnFailure());
    end;

    procedure SetTestOutput(TestOutputText: Text)
    begin
        Preload();
        AITTestContext.SetTestOutput(TestOutputText);
    end;

    procedure SetTestOutput(Context: Text; Question: Text; Answer: Text)
    begin
        Preload();
        AITTestContext.SetTestOutput(Context, Question, Answer);
    end;

    procedure SetQueryResponse(Query: Text; Response: Text)
    begin
        Preload();
        AITTestContext.SetQueryResponse(Query, Response);
    end;

    procedure SetAnswerForQnAEvaluation(Answer: Text)
    begin
        Preload();
        AITTestContext.SetAnswerForQnAEvaluation(Answer);
    end;

    procedure AddMessage(Content: Text; Role: Text)
    begin
        Preload();
        AITTestContext.AddMessage(Content, Role);
    end;

    procedure SetTestMetric(TestMetric: Text)
    begin
        Preload();
        AITTestContext.SetTestMetric(TestMetric);
    end;

    procedure SetAccuracy(Accuracy: Decimal)
    begin
        AITTestContext.SetAccuracy(Accuracy);
    end;

    procedure SetTokenConsumption(TokensUsed: Integer)
    begin
        AITTestContext.SetTokenConsumption(TokensUsed);
    end;

    procedure NextTurn(): Boolean
    begin
        Preload();
        exit(AITTestContext.NextTurn());
    end;

    procedure GetCurrentTurn(): Integer
    begin
        exit(AITTestContext.GetCurrentTurn());
    end;
}
