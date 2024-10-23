// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AIEvaluate;

codeunit 50050 "Example"
{
    Subtype = Test;

    [Test]
    procedure TestWithPredefinedEvaluator()
    var
        AIEvaluate: Codeunit "AI Evaluate";
        AIEvaluator: Codeunit "AI Evaluator";
        Query: Text;
        Response: Text;
        Input: JsonObject;
        Output: JsonObject;
        OutputScore: JsonToken;
        Score: Decimal;
    begin
        // Get query and response
        Query := 'Where can I get my car fixed?';
        Response := MockLLMCall(Query);

        // Set input for evaluation
        Input.Add('query', Query);
        Input.Add('response', Response);

        // Set up evaluator
        AIEvaluator.Initialize("AI Evaluator"::Relevance);

        // Evaluate
        Output := AIEvaluate.Evaluate(Input, AIEvaluator);

        // Get score
        Output.Get('apology', OutputScore);
        Score := OutputScore.AsValue().AsInteger();

        if Score < 4.0 then
            Error('Relevance is low.')
    end;

    [Test]
    procedure TestWithCustomEvaluator()
    var
        AIEvaluate: Codeunit "AI Evaluate";
        AIEvaluator: Codeunit "AI Evaluator";
        Query: Text;
        Response: Text;
        Input: JsonObject;
        Output: JsonObject;
        OutputScore: JsonToken;
        Score: Integer;
        ApologyEvaluatorStream: InStream;
    begin
        // Get query and response
        Query := 'Where can I get my car fixed?';
        Response := MockLLMCall(Query);

        // Set input for evaluation
        Input.Add('query', Query);
        Input.Add('response', Response);

        // Set up evaluator
        NavApp.GetResource('apology.prompty', ApologyEvaluatorStream, TextEncoding::UTF8);
        AIEvaluator.InitializeFrom(ApologyEvaluatorStream);

        // Evaluate
        Output := AIEvaluate.Evaluate(Input, AIEvaluator);

        // Get score
        Output.Get('apology', OutputScore);
        Score := OutputScore.AsValue().AsInteger();

        if Score = 1 then
            Error('It apologized.')
    end;

    procedure MockLLMCall(Query: Text): Text
    begin
        exit('I''m sorry, I don''t know that. Would you like me to look it up for you?');
    end;
}