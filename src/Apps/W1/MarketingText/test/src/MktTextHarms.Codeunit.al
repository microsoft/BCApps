namespace System.Text.Test;

using System.TestTools.AITestToolkit;
using System.Text;

codeunit 133553 MktTextHarms
{
    Subtype = Test;
    TestType = AITest;
    TestPermissions = Disabled;

    [Test]
    procedure TaglineTest()
    begin
        this.RunTest(Enum::"Entity Text Format"::Tagline, Enum::"Entity Text Tone"::Inspiring);
    end;

    [Test]
    procedure TaglineParagraphTest()
    begin
        this.RunTest(Enum::"Entity Text Format"::TaglineParagraph, Enum::"Entity Text Tone"::Inspiring);
    end;

    [Test]
    procedure ParagraphTest()
    begin
        this.RunTest(Enum::"Entity Text Format"::Paragraph, Enum::"Entity Text Tone"::Formal);
    end;

    [Test]
    procedure BriefTest()
    begin
        this.RunTest(Enum::"Entity Text Format"::Brief, Enum::"Entity Text Tone"::Inspiring);
    end;

    local procedure RunTest(Format: Enum "Entity Text Format"; Tone: Enum "Entity Text Tone")
    var
        AITestContext: Codeunit "AIT Test Context";
        MTPromptEvaluator: Codeunit "MT Prompt Evaluator";
        Facts: Dictionary of [Text, Text];
        Response: Text;
        Harm: Text;
        GenerationError: Text;
        RefusalTxt: Label 'Sorry, we could not generate a good suggestion for this. Review the information provided, consider your choice of words, and try again.', Locked = true;
    begin
        Harm := AITestContext.GetInput().Element('harm').ValueAsText();
        if Harm = '' then
            Error(MissingHarmErr);
        this.GetFactsWithHarmFromTestInput(Facts, Harm);
        ClearLastError();
        if not this.GenerateText(Facts, Tone, Format, Response) then begin
            GenerationError := GetLastErrorText();
            // Only the Entity Text refusal is an acceptable generation failure.
            if GenerationError <> RefusalTxt then
                Error(GenerationError);
            Response := GenerationError;
        end;
        this.SetTestOutput(Facts, Response, Tone, Format);
        MTPromptEvaluator.Evaluate(SafetyPromptLbl, this.BuildFactsText(Facts), Response);
    end;

    [TryFunction]
    local procedure GenerateText(Facts: Dictionary of [Text, Text]; Tone: Enum "Entity Text Tone"; Format: Enum "Entity Text Format"; var Response: Text)
    var
        EntityText: Codeunit "Entity Text";
    begin
        Response := EntityText.GenerateText(Facts, Tone, Format, Enum::"Entity Text Emphasis"::None);
    end;

    local procedure GetFactsWithHarmFromTestInput(var Values: Dictionary of [Text, Text]; Harm: Text)
    var
        AITestContext: Codeunit "AIT Test Context";
        InputJson: JsonObject;
        InputToken: JsonToken;
        KeysList: List of [Text];
        KeyValue: Text;
        Value: Text;
        I: Integer;
        KeysCount: Integer;
    begin
        InputJson := AITestContext.GetInput().ValueAsJsonObject();
        InputJson.Get('values', InputToken);

        InputJson := InputToken.AsObject();

        KeysList := InputJson.Keys;
        KeysCount := KeysList.Count();

        for I := 1 to KeysCount do begin
            KeysList.Get(I, KeyValue);
            InputJson.Get(KeyValue, InputToken);
            Value := InputToken.AsValue().AsText();
            Value := Value.Replace('{{harm}}', Harm);
            Values.Add(KeyValue, Value);
        end;
    end;

    local procedure BuildFactsText(var Facts: Dictionary of [Text, Text]): Text
    var
        FactTemplateTxt: Label '- %1: %2%3', Locked = true;
        FactKey: Text;
        FactValue: Text;
        FactsList: Text;
        NewLineChar: Char;
        MaxFacts: Integer;
        TotalFacts: Integer;
        MaxFactLength: Integer;
    begin
        NewLineChar := 10;
        TotalFacts := Facts.Count();

        MaxFacts := 20;
        MaxFactLength := 250;

        TotalFacts := 0;
        foreach FactKey in Facts.Keys() do begin
            if TotalFacts < MaxFacts then begin
                Facts.Get(FactKey, FactValue);
                FactKey := FactKey.Replace(NewLineChar, '').Trim();
                FactValue := FactValue.Replace(NewLineChar, '').Trim();
                FactsList += StrSubstNo(FactTemplateTxt, CopyStr(FactKey, 1, MaxFactLength), CopyStr(FactValue, 1, MaxFactLength), NewLineChar);
            end;
            TotalFacts += 1;
        end;
        exit(FactsList);
    end;

    local procedure SetTestOutput(Facts: Dictionary of [Text, Text]; Response: Text; Tone: Enum "Entity Text Tone"; Format: Enum "Entity Text Format")
    var
        AITestContext: Codeunit "AIT Test Context";
        Context: Text;
        Request: Text;
        FactsText: Text;
        EncodedNewlineTok: Label '<br />', Locked = true;
        NewLineChar: Char;
    begin
        NewLineChar := 10;
        FactsText := this.BuildFactsText(Facts).Replace(NewLineChar, EncodedNewlineTok);
        Context := 'Here are some facts about the item:<br /><br />' + FactsText;
        Request := 'Write a marketing text for: ' + FactsText + ' <br /> Tone: ' + Tone.Names.Get(Tone.Ordinals.IndexOf(Tone.AsInteger())) + ', Format: ' + Format.Names.Get(Format.Ordinals.IndexOf(Format.AsInteger()));

        AITestContext.SetTestOutput(Context, Request, Response);
    end;

    var
        MissingHarmErr: Label 'The test input must provide a non-empty harm value.';
        SafetyPromptLbl: Label 'evaluation_prompts/safety.prompty', Locked = true;
}