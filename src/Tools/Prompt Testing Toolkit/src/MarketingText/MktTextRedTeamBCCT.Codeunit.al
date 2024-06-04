namespace System.Tooling;

using System.Text;

codeunit 149038 "Mkt Text RedTeam BCCT"
{
    Subtype = Test;

    [Test]
    procedure TaglineTest()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        InputJson: JsonObject;
        InputToken: JsonToken;
        InputPrompt: Text;
        Response: Text;
    begin
        InputJson.ReadFrom(BCCTTestContext.GetInput());
        InputJson.Get('inputPrompt', InputToken);
        InputPrompt := InputToken.AsValue().AsText();

        Format := Enum::"Entity Text Format"::Tagline;
        AddFacts(Facts, InputPrompt, Format);
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Inspiring, Format));
    end;

    [Test]
    procedure TaglineParagraphTest()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        InputJson: JsonObject;
        InputToken: JsonToken;
        InputPrompt: Text;
        Response: Text;
    begin
        InputJson.ReadFrom(BCCTTestContext.GetInput());
        InputJson.Get('inputPrompt', InputToken);
        InputPrompt := InputToken.AsValue().AsText();

        Format := Enum::"Entity Text Format"::TaglineParagraph;
        AddFacts(Facts, InputPrompt, Format);
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Inspiring, Format));
    end;

    [Test]
    procedure ParagraphTest()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        InputJson: JsonObject;
        InputToken: JsonToken;
        InputPrompt: Text;
        Response: Text;
    begin
        InputJson.ReadFrom(BCCTTestContext.GetInput());
        InputJson.Get('inputPrompt', InputToken);
        InputPrompt := InputToken.AsValue().AsText();

        Format := Enum::"Entity Text Format"::Paragraph;
        AddFacts(Facts, InputPrompt, Format);
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Inspiring, Format));
    end;

    [Test]
    procedure BriefTest()
    var
        BCCTTestContext: Codeunit "BCCT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        InputJson: JsonObject;
        InputToken: JsonToken;
        InputPrompt: Text;
        Response: Text;
    begin
        InputJson.ReadFrom(BCCTTestContext.GetInput());
        InputJson.Get('inputPrompt', InputToken);
        InputPrompt := InputToken.AsValue().AsText();

        Format := Enum::"Entity Text Format"::Brief;
        AddFacts(Facts, InputPrompt, Format);
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);
        BCCTTestContext.SetTestOutput(PrepareOutput(InputPrompt, Response, Enum::"Entity Text Tone"::Inspiring, Format));
    end;

    local procedure AddFacts(var Facts: Dictionary of [Text, Text]; InputPrompt: Text; Format: Enum "Entity Text Format")
    begin
        Facts.Add('Name', InputPrompt);
        Facts.Add(InputPrompt, InputPrompt);
        if Format <> Enum::"Entity Text Format"::Tagline then begin
            Facts.Add('Fact', InputPrompt);
            Facts.Add('No', InputPrompt);
        end;
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