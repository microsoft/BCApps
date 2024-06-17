// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Text;

codeunit 149038 "Mkt Text RedTeam BCCT"
{
    Subtype = Test;

    [Test]
    procedure TaglineTest()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        InputJson: JsonObject;
        InputToken: JsonToken;
        InputPrompt: Text;
        Response: Text;
    begin
        InputJson.ReadFrom(AITTestContext.GetInput());
        InputJson.Get('inputPrompt', InputToken);
        InputPrompt := InputToken.AsValue().AsText();

        Format := Enum::"Entity Text Format"::Tagline;
        AddFacts(Facts, InputPrompt, Format);
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Format), Response, Enum::"Entity Text Tone"::Inspiring, Format));
    end;

    [Test]
    procedure TaglineParagraphTest()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        InputJson: JsonObject;
        InputToken: JsonToken;
        InputPrompt: Text;
        Response: Text;
    begin
        InputJson.ReadFrom(AITTestContext.GetInput());
        InputJson.Get('inputPrompt', InputToken);
        InputPrompt := InputToken.AsValue().AsText();

        Format := Enum::"Entity Text Format"::TaglineParagraph;
        AddFacts(Facts, InputPrompt, Format);
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Format), Response, Enum::"Entity Text Tone"::Inspiring, Format));
    end;

    [Test]
    procedure ParagraphTest()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        InputJson: JsonObject;
        InputToken: JsonToken;
        InputPrompt: Text;
        Response: Text;
    begin
        InputJson.ReadFrom(AITTestContext.GetInput());
        InputJson.Get('inputPrompt', InputToken);
        InputPrompt := InputToken.AsValue().AsText();

        Format := Enum::"Entity Text Format"::Paragraph;
        AddFacts(Facts, InputPrompt, Format);
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Format), Response, Enum::"Entity Text Tone"::Inspiring, Format));
    end;

    [Test]
    procedure BriefTest()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        InputJson: JsonObject;
        InputToken: JsonToken;
        InputPrompt: Text;
        Response: Text;
    begin
        InputJson.ReadFrom(AITTestContext.GetInput());
        InputJson.Get('inputPrompt', InputToken);
        InputPrompt := InputToken.AsValue().AsText();

        Format := Enum::"Entity Text Format"::Brief;
        AddFacts(Facts, InputPrompt, Format);
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Format), Response, Enum::"Entity Text Tone"::Inspiring, Format));
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

    local procedure BuildFactsText(var Facts: Dictionary of [Text, Text]; TextFormat: Enum "Entity Text Format"): Text
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

    local procedure PrepareOutput(InputPrompt: Text; Facts: Text; Response: Text; Tone: Enum "Entity Text Tone"; Format: Enum "Entity Text Format"): Text;
    var
        Context: Text;
        FormatLbl: Label '{"question": "METAPROMPT %1", "answer": "%2", "context": "%3", "ground_truth": "%4", "tone": "%5", "format" : "%6"}', Comment = '%1= Input Prompt, %2= Response Prompt, %3= Context, %4= Ground Truth, %5= Tone, %6= Format';
        EncodedNewlineTok: Label '<br />', Locked = true;
        NewLineChar: Char;
    begin
        NewLineChar := 10;
        Context := 'Here are some facts about the item:<br /><br />' + Facts.Replace(NewLineChar, EncodedNewlineTok);
        exit(StrSubstNo(FormatLbl, Facts.Replace(NewLineChar, EncodedNewlineTok), Response.Replace(NewLineChar, EncodedNewlineTok), Context, '', Tone.Names.Get(Tone.Ordinals.IndexOf(Tone.AsInteger())), Format.Names.Get(Format.Ordinals.IndexOf(Format.AsInteger()))));
    end;


}