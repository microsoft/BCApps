namespace System.Tooling;

using System.Text;

codeunit 149039 "Mkt Text Accuracy BCCT"
{
    Subtype = Test;

    [Test]
    procedure TaglineParagraphInspiring()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := BCCTTestContext.GetInput();
        Response := EntityTextCod.GenerateText(LineInputToDictionary(InputPrompt), Enum::"Entity Text Tone"::Inspiring, Enum::"Entity Text Format"::TaglineParagraph, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Inspiring, Enum::"Entity Text Format"::TaglineParagraph));
    end;

    [Test]
    procedure TaglineParagraphFormal()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := BCCTTestContext.GetInput();
        Response := EntityTextCod.GenerateText(LineInputToDictionary(InputPrompt), Enum::"Entity Text Tone"::Formal, Enum::"Entity Text Format"::TaglineParagraph, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Formal, Enum::"Entity Text Format"::TaglineParagraph));
    end;

    [Test]
    procedure TaglineParagraphCreative()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := BCCTTestContext.GetInput();
        Response := EntityTextCod.GenerateText(LineInputToDictionary(InputPrompt), Enum::"Entity Text Tone"::Creative, Enum::"Entity Text Format"::TaglineParagraph, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Creative, Enum::"Entity Text Format"::TaglineParagraph));
    end;

    [Test]
    procedure TaglineInspiring()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := BCCTTestContext.GetInput();
        Response := EntityTextCod.GenerateText(LineInputToDictionary(InputPrompt), Enum::"Entity Text Tone"::Inspiring, Enum::"Entity Text Format"::Tagline, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Inspiring, Enum::"Entity Text Format"::Tagline));
    end;

    [Test]
    procedure TaglineFormal()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := BCCTTestContext.GetInput();
        Response := EntityTextCod.GenerateText(LineInputToDictionary(InputPrompt), Enum::"Entity Text Tone"::Formal, Enum::"Entity Text Format"::Tagline, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Formal, Enum::"Entity Text Format"::Tagline));
    end;

    [Test]
    procedure TaglineCreative()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := BCCTTestContext.GetInput();
        Response := EntityTextCod.GenerateText(LineInputToDictionary(InputPrompt), Enum::"Entity Text Tone"::Creative, Enum::"Entity Text Format"::Tagline, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Creative, Enum::"Entity Text Format"::Tagline));
    end;

    [Test]
    procedure BriefInspiring()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := BCCTTestContext.GetInput();
        Response := EntityTextCod.GenerateText(LineInputToDictionary(InputPrompt), Enum::"Entity Text Tone"::Inspiring, Enum::"Entity Text Format"::Brief, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Inspiring, Enum::"Entity Text Format"::Brief));
    end;

    [Test]
    procedure BriefFormal()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := BCCTTestContext.GetInput();
        Response := EntityTextCod.GenerateText(LineInputToDictionary(InputPrompt), Enum::"Entity Text Tone"::Formal, Enum::"Entity Text Format"::Brief, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Formal, Enum::"Entity Text Format"::Brief));
    end;

    [Test]
    procedure BriefCreative()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := BCCTTestContext.GetInput();
        Response := EntityTextCod.GenerateText(LineInputToDictionary(InputPrompt), Enum::"Entity Text Tone"::Creative, Enum::"Entity Text Format"::Brief, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Creative, Enum::"Entity Text Format"::Brief));
    end;


    local procedure LineInputToDictionary(Input: Text): Dictionary of [Text, Text];
    var
        Attributes: Dictionary of [Text, Text];
        InputJson: JsonObject;
        AttributeValueToken: JsonToken;
        AttributeKey: Text;
    begin
        InputJson.ReadFrom(Input);

        foreach AttributeKey in InputJson.Keys() do begin
            InputJson.Get(AttributeKey, AttributeValueToken);
            Attributes.Add(AttributeKey, AttributeValueToken.AsValue().AsText());
        end;

        exit(Attributes);
    end;

    local procedure PrepareOutput(InputPrompt: Text; Response: Text; Tone: Enum "Entity Text Tone"; Format: Enum "Entity Text Format"): Text;
    var
        Context: Text;
        FormatLbl: Label '{"question": "%1", "answer": "%2", "context": "%3", "ground_truth": "%4", "tone": "%5", "format" : "%6"}', Comment = '%1= Input Prompt, %2= Response Prompt, %3= Context, %4= Ground Truth, %5= Tone, %6= Format';
    begin
        Context := 'The following facts should only be used to produce the marketing ad:\\n' + InputPrompt;
        exit(StrSubstNo(FormatLbl, InputPrompt, Response, Context, '', Tone.Names.Get(Tone.Ordinals.IndexOf(Tone.AsInteger())), Format.Names.Get(Format.Ordinals.IndexOf(Format.AsInteger()))));
    end;

}