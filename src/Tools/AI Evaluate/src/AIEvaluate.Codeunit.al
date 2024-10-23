// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AIEvaluate;

/// <summary>
/// Exposes functions that can be used by the AI tests.
/// </summary>
codeunit 50001 "AI Evaluate"
{

    /// <summary>
    /// Evaluates the input and returns a result.
    /// </summary>
    /// <param name="Query">Input to evaluate. Can be left empty if not relevant for evaluator.</param>
    /// <param name="Response">Input to evaluate. Can be left empty if not relevant for evaluator.</param>
    /// <param name="Context">Input to evaluate. Can be left empty if not relevant for evaluator.</param>
    /// <param name="GroundTruth">Input to evaluate. Can be left empty if not relevant for evaluator.</param>
    /// <param name="Evaluator">Evaluator to use.</param>
    /// <remarks>Query</remarks>
    /// <returns>A dictionary of name, score</returns>
    procedure Evaluate(Query: Text; Response: Text; Context: Text; GroundTruth: Text; Evaluator: Codeunit "AI Evaluator"): JsonObject
    begin
        exit(AIEvaluateImpl.Evaluate(Query, Response, Context, GroundTruth, Evaluator));
    end;

    /// <summary>
    /// Evaluates the input and returns a result.
    /// </summary>
    /// <param name="Input">Input to evaluate.</param>
    /// <param name="Evaluator">Evaluator to use.</param>
    /// <returns>A dictionary of name, score</returns>
    procedure Evaluate(Input: JsonObject; Evaluator: Codeunit "AI Evaluator"): JsonObject
    begin
        exit(AIEvaluateImpl.Evaluate(Input, Evaluator));
    end;


    var
        AIEvaluateImpl: Codeunit "AI Evaluate Impl.";
}