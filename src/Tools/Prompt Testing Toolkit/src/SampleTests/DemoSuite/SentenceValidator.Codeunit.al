namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;
codeunit 149031 SentenceValidator
{
    Access = Internal;
    Subtype = Test;

    [Test]
    procedure AssertSentenceLengthFunction()
    var
        // TestInput: Codeunit "Test Input";
        BCCTContext: Codeunit "BCCT Test Context";
        // UserInputKeyLbl: Label 'input', Locked = true;
        UserInput: Text;
    begin
        // BCCTContext.StartScenario('Scene1');
        // UserInput := TestInput.GetTestInput(UserInputKeyLbl).ValueAsText();
        UserInput := BCCTContext.GetInput();
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
        TestInput: Codeunit "Test Input";
        // TestOutput: Codeunit "Test Output";
        UserInputKeyLbl: Label 'input', Locked = true;
        UserInput: Text;
        Sentence: Text;
    // JsonSentenceKeyLbl: Label 'sentence', Locked = true;
    begin
        UserInput := TestInput.GetTestInput(UserInputKeyLbl).ValueAsText();
        // Generate a sentence based on the user input
        Sentence := 'I hope you like the generated text based on ' + UserInput;

        // Write the generated sentence to the output
        // TestOutput.TestData().Add(JsonSentenceKeyLbl, Sentence);
        BCCTTestContext.SetTestOutput(Sentence);

        // BCCTTestContext.SetTestOutput(Sentence);
    end;
}