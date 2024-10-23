// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AIEvaluate;

/// <summary>
/// Exposes functions that can be used by the AI tests.
/// </summary>
codeunit 50006 "AI Evaluator Impl."
{
    Access = Internal;

    var
        Initialized: Boolean;

    procedure Initialize(AIEvaluator: Enum "AI Evaluator")
    begin
        Initialized := true;
        exit; // TODO: Create one
    end;

    procedure InitializeFrom(InStream: InStream)
    begin
        Initialized := true;
        exit; // TODO: Load from Prompty
    end;
}