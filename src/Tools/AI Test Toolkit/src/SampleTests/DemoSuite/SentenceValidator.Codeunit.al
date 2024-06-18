namespace System.TestTools.AITestToolkit;
codeunit 149031 SentenceValidator
{
    Access = Internal;
    Subtype = Test;

    [Test]
    procedure AssertSentenceLengthFunction()
    var
        AITContext: Codeunit "AIT Test Context";
        UserInput: Text;
    begin
        // AITContext.StartScenario('Scene1');
        // UserInput := TestInput.GetTestInput(UserInputKeyLbl).ValueAsText();
        UserInput := AITContext.GetQuestionAsText();
        // AITContext.SetScenarioOutput('Scene1', 'User input: ' + UserInput);
        // Sleep(100);
        // AITContext.EndScenario('Scene1');
        if StrLen(UserInput) > 50 then
            Error('Length exceeds 50 characters');
    end;

    [Test]
    procedure EvaluateGeneratedSentenceGrammarExternally()
    var
        AITTestContext: Codeunit "AIT Test Context";
        Sentence: Text;
    begin
        // Generate a sentence based on the user input
        Sentence := 'I hope you like the generated text based on ' + AITTestContext.GetQuestionAsText();

        // Write the generated sentence to the output
        AITTestContext.SetTestOutput(Sentence);
    end;
}