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
        UserInput := AITContext.GetQuestionAsText();
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