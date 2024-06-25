// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Text;

codeunit 149039 "Mkt Text Accuracy BCCT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TaglineParagraphInspiring()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        Category: Text;
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := AITTestContext.GetInput();
        Facts := LineInputToDictionary(InputPrompt);
        Format := Enum::"Entity Text Format"::TaglineParagraph;
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);

        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Category, Format), Category, Response, Enum::"Entity Text Tone"::Inspiring, Format));
    end;

    [Test]
    procedure TaglineParagraphFormal()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        Category: Text;
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := AITTestContext.GetInput();
        Facts := LineInputToDictionary(InputPrompt);
        Format := Enum::"Entity Text Format"::TaglineParagraph;
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Formal, Format, Enum::"Entity Text Emphasis"::None);

        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Category, Format), Category, Response, Enum::"Entity Text Tone"::Formal, Format));
    end;

    [Test]
    procedure TaglineParagraphCreative()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        Category: Text;
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := AITTestContext.GetInput();
        Facts := LineInputToDictionary(InputPrompt);
        Format := Enum::"Entity Text Format"::TaglineParagraph;
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Creative, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Category, Format), Category, Response, Enum::"Entity Text Tone"::Creative, Format));
    end;

    [Test]
    procedure TaglineInspiring()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        Category: Text;
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := AITTestContext.GetInput();
        Facts := LineInputToDictionary(InputPrompt);
        Format := Enum::"Entity Text Format"::Tagline;
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Category, Format), Category, Response, Enum::"Entity Text Tone"::Inspiring, Format));
    end;

    [Test]
    procedure TaglineFormal()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        Category: Text;
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := AITTestContext.GetInput();
        Facts := LineInputToDictionary(InputPrompt);
        Format := Enum::"Entity Text Format"::Tagline;
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Formal, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Category, Format), Category, Response, Enum::"Entity Text Tone"::Formal, Format));
    end;

    [Test]
    procedure TaglineCreative()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        Category: Text;
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := AITTestContext.GetInput();
        Facts := LineInputToDictionary(InputPrompt);
        Format := Enum::"Entity Text Format"::Tagline;
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Creative, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Category, Format), Category, Response, Enum::"Entity Text Tone"::Creative, Format));
    end;

    [Test]
    procedure BriefInspiring()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        Category: Text;
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := AITTestContext.GetInput();
        Facts := LineInputToDictionary(InputPrompt);
        Format := Enum::"Entity Text Format"::Brief;
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Inspiring, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Category, Format), Category, Response, Enum::"Entity Text Tone"::Inspiring, Format));
    end;

    [Test]
    procedure BriefFormal()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        Category: Text;
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := AITTestContext.GetInput();
        Facts := LineInputToDictionary(InputPrompt);
        Format := Enum::"Entity Text Format"::Brief;
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Formal, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Category, Format), Category, Response, Enum::"Entity Text Tone"::Formal, Format));
    end;

    [Test]
    procedure BriefCreative()
    var
        AITTestContext: Codeunit "AIT Test Context";
        EntityTextCod: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Format: Enum "Entity Text Format";
        Category: Text;
        InputPrompt: Text;
        Response: Text;
    begin
        InputPrompt := AITTestContext.GetInput();
        Facts := LineInputToDictionary(InputPrompt);
        Format := Enum::"Entity Text Format"::Brief;
        Response := EntityTextCod.GenerateText(Facts, Enum::"Entity Text Tone"::Creative, Format, Enum::"Entity Text Emphasis"::None);
        AITTestContext.SetTestOutput(PrepareOutput(InputPrompt, BuildFactsText(Facts, Category, Format), Category, Response, Enum::"Entity Text Tone"::Creative, Format));
    end;

    local procedure BuildFactsText(var Facts: Dictionary of [Text, Text]; var Category: Text; TextFormat: Enum "Entity Text Format"): Text
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
                if (Category = '') and FactKey.Contains('Category') then
                    Category := FactValue
                else
                    FactsList += StrSubstNo(FactTemplateTxt, CopyStr(FactKey, 1, MaxFactLength), CopyStr(FactValue, 1, MaxFactLength), NewLineChar);
            end;
            TotalFacts += 1;
        end;
        exit(FactsList);
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

    local procedure PrepareOutput(InputPrompt: Text; Facts: Text; Category: Text; Response: Text; Tone: Enum "Entity Text Tone"; Format: Enum "Entity Text Format"): Text;
    var
        Context: Text;
        FormatLbl: Label '{"question": "METAPROMPT %6 %5: %1", "answer": "%2", "context": "%3", "ground_truth": "%4", "tone": "%5", "format" : "%6"}', Comment = '%1= Input Prompt, %2= Response Prompt, %3= Context, %4= Ground Truth, %5= Tone, %6= Format';
        EncodedNewlineTok: Label '<br />', Locked = true;
        NewLineChar: Char;
    begin
        NewLineChar := 10;
        Context := 'Here are some facts about the item:<br /><br />' + Facts.Replace(NewLineChar, EncodedNewlineTok) + '<br /> This is in the category of: ' + Category.Replace(NewLineChar, EncodedNewlineTok);
        exit(StrSubstNo(FormatLbl, Facts.Replace(NewLineChar, EncodedNewlineTok), Response.Replace(NewLineChar, EncodedNewlineTok), Context, '', Tone.Names.Get(Tone.Ordinals.IndexOf(Tone.AsInteger())), Format.Names.Get(Format.Ordinals.IndexOf(Format.AsInteger()))));
    end;

}