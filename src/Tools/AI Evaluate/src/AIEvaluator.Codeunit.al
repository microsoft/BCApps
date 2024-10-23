// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AIEvaluate;

/// <summary>
/// Stateful representation of an evaluator.
/// </summary>
codeunit 50005 "AI Evaluator"
{
    /// <summary>
    /// Initialized pre-defined evaluator.
    /// </summary>
    procedure Initialize(AIEvaluator: Enum "AI Evaluator")
    begin
        AIEvaluatorImpl.Initialize(AIEvaluator);
    end;


    /// <summary>
    /// Initializes AI evaluator from Prompty file.
    /// </summary>
    procedure InitializeFrom(InStream: InStream)
    begin
        AIEvaluatorImpl.InitializeFrom(InStream);
    end;

    procedure GetSystemPrompt(): Text
    begin
        exit('')
    end;

    procedure GetAssistantMessage(): Text
    begin
        exit('')
    end;


    procedure GetUserMessage(): Text
    begin
        exit('')
    end;

    var
        AIEvaluatorImpl: Codeunit "AI Evaluator Impl.";
}