namespace System.Text.Test;

using System.TestLibraries.Utilities;

codeunit 133555 "MT Prompt Evaluator Tests"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        MTPromptEvaluator: Codeunit "MT Prompt Evaluator";

    [Test]
    procedure RenderPromptPreservesPlaceholdersInInput()
    var
        SystemPrompt: Text;
        UserPrompt: Text;
        NewLine: Char;
    begin
        NewLine := 10;
        MTPromptEvaluator.RenderPrompt(
            '---' + NewLine + 'name: test' + NewLine + '---' + NewLine +
            'system:' + NewLine + 'Evaluate data.' + NewLine + 'user:' + NewLine + '{{context}} / {{response}}',
            'literal {{response}}', 'literal {{context}}', SystemPrompt, UserPrompt);

        Assert.AreEqual('Evaluate data.', SystemPrompt, 'Metadata must not be sent as a system message.');
        Assert.AreEqual('literal {{response}} / literal {{context}}', UserPrompt, 'Input data must not be rendered as template syntax.');
    end;

    [Test]
    procedure RenderPromptRejectsMissingMessages()
    var
        SystemPrompt: Text;
        UserPrompt: Text;
    begin
        asserterror MTPromptEvaluator.RenderPrompt('---', '', '', SystemPrompt, UserPrompt);
        Assert.ExpectedError('The evaluation prompt must contain system and user messages');
    end;

    [Test]
    procedure EvaluationRejectsLowScore()
    var
        Output: JsonObject;
    begin
        Output.ReadFrom('{"score":3,"explanation":"Not grounded."}');
        asserterror MTPromptEvaluator.ValidateEvaluation(Output, 'groundedness');
        Assert.ExpectedError('groundedness validation failed. Score: 3');
    end;

    [Test]
    procedure EvaluationRejectsOutOfRangeScore()
    var
        Output: JsonObject;
    begin
        Output.ReadFrom('{"score":6,"explanation":"Invalid score."}');
        asserterror MTPromptEvaluator.ValidateEvaluation(Output, 'groundedness');
        Assert.ExpectedError('must be between 1 and 5');
    end;

    [Test]
    procedure EvaluationAcceptsThresholdScore()
    var
        Output: JsonObject;
    begin
        Output.ReadFrom('{"score":4,"explanation":"Grounded."}');
        MTPromptEvaluator.ValidateEvaluation(Output, 'groundedness');
    end;
}
