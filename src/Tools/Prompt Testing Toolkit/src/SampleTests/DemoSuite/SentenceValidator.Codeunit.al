namespace System.Tooling;
codeunit 149031 SentenceValidator
{
    Access = Internal;
    Subtype = Test;

    [Test]
    procedure AssertSentenceLengthFunction()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        JsonContent: JsonObject;
        JsonToken: JsonToken;
        UserInputKeyLbl: Label 'input', Locked = true;
        UserInput: Text;
    begin
        JsonContent.ReadFrom(BCCTTestContext.GetInput());
        JsonContent.Get(UserInputKeyLbl, JsonToken);
        UserInput := JsonToken.AsValue().AsText();
        if StrLen(UserInput) > 50 then
            Error('Length exceeds 50 characters');
    end;

    [Test]
    procedure EvaluateGeneratedSentenceGrammarExternally()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        JsonContent: JsonObject;
        JsonToken: JsonToken;
        UserInputKeyLbl: Label 'input', Locked = true;
        UserInput: Text;
        Sentence: Text;
        JsonSentenceKeyLbl: Label 'sentence', Locked = true;
        Result: Text;
    begin
        JsonContent.ReadFrom(BCCTTestContext.GetInput());
        JsonContent.Get(UserInputKeyLbl, JsonToken);
        UserInput := JsonToken.AsValue().AsText();
        // Generate a sentence based on the user input
        Sentence := 'I hope you like the generated text based on ' + UserInput;

        // Write the generated sentence to the output
        Clear(JsonContent);
        JsonContent.Add(JsonSentenceKeyLbl, Sentence);
        JsonContent.WriteTo(Result);
        BCCTTestContext.SetTestOutput(Result);
    end;
}