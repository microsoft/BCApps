// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

// TODO: Remove this CU before merge

codeunit 149050 "Multi-turn Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    // Example test method that can handle input with 1 to 3 turns.
    procedure TestMultiTurn()
    var
        AITTestContext: Codeunit "AIT Test Context";
        Output: Text;
        OutputTok: Label 'Output generated from: %1', Locked = true;
        ExampleSetupLbl: Label 'example setup', Locked = true;
    begin
        // Turn 1
        if AITTestContext.GetTestSetup().ValueAsText() <> ExampleSetupLbl then
            Error('Missing test setup in turn 1');

        Output := StrSubstNo(OutputTok, AITTestContext.GetQuestion().ValueAsText());
        AITTestContext.SetTestOutput('', AITTestContext.GetQuestion().ValueAsText(), Output);

        if not AITTestContext.SetNextTurn() then
            exit;

        // Turn 2
        if AITTestContext.GetTestSetup().ValueAsText() <> ExampleSetupLbl then
            Error('Missing test setup in turn 1');

        Output := StrSubstNo(OutputTok, AITTestContext.GetQuestion().ValueAsText());
        AITTestContext.SetTestOutput('', AITTestContext.GetQuestion().ValueAsText(), Output);

        if not AITTestContext.SetNextTurn() then
            exit;

        // Turn 3
        if AITTestContext.GetTestSetup().ValueAsText() <> ExampleSetupLbl then
            Error('Missing test setup in turn 1');

        Output := StrSubstNo(OutputTok, AITTestContext.GetQuestion().ValueAsText());
        AITTestContext.SetTestOutput('', AITTestContext.GetQuestion().ValueAsText(), Output);

        if not AITTestContext.SetNextTurn() then
            exit;

        Error('Unexpected turn');
    end;
}