namespace System.TestTools.AITestToolkit;
codeunit 149031 SentenceValidator
{
    Access = Internal;
    Subtype = Test;

    [Test]
    procedure AssertSentenceLengthFunction()
    var
        BCCTContext: Codeunit "BCCT Test Context";
        UserInput: Text;
    begin
        // BCCTContext.StartScenario('Scene1');
        // UserInput := TestInput.GetTestInput(UserInputKeyLbl).ValueAsText();
        UserInput := BCCTContext.GetUserQuery();
        // BCCTContext.SetScenarioOutput('Scene1', 'User input: ' + UserInput);
        // Sleep(100);
        // BCCTContext.EndScenario('Scene1');
        if StrLen(UserInput) > 50 then
            Error('Length exceeds 50 characters');
    end;

    [Test]
    procedure EvaluateGeneratedSentenceGrammarExternally()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        Sentence: Text;
    begin
        // Generate a sentence based on the user input
        Sentence := 'I hope you like the generated text based on ' + BCCTTestContext.GetUserQuery();

        // Write the generated sentence to the output
        BCCTTestContext.SetTestOutput(Sentence);
    end;
}