namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;
codeunit 149031 SentenceValidator
{
    Access = Internal;
    Subtype = Test;

    [Test]
    procedure AssertSentenceLengthFunction()
    var
        AITContext: Codeunit "AIT Test Context";
        TestInputJson: Codeunit "Test Input Json";
        UserInput: Text;
        ExpectedMaxLength: Integer;
        LengthErr: Label 'Length exceeds %1 characters', Comment = '%1 = Expected Max Length';
    begin
        UserInput := AITContext.GetQuestionAsText();
        TestInputJson := AITContext.GetInputAsJson();
        ExpectedMaxLength := TestInputJson.Element('ExpectedMaxLength').ValueAsInteger();
        if StrLen(UserInput) > ExpectedMaxLength then
            Error(LengthErr, ExpectedMaxLength);
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