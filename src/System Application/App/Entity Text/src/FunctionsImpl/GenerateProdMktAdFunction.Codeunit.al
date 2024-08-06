// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

using System.AI;
using System.Telemetry;

codeunit 2017 "Generate Prod Mkt Ad Function" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FunctionNameLbl: Label 'generate_product_marketing_ad', Locked = true;
        TextFormat: Enum "Entity Text Format";

    [NonDebuggable]
    procedure GetPrompt(): JsonObject
    var
        Prompt: Codeunit "Entity Text Prompts";
        PromptJson: JsonObject;
    begin
        PromptJson.ReadFrom(Prompt.GetGenerateProdMktAdFuncPrompt(TextFormat));
        exit(PromptJson);
    end;

    [NonDebuggable]
    procedure Execute(Arguments: JsonObject): Variant
    var
        EntityTextImpl: Codeunit "Entity Text Impl.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FeatureTelemetryCD: Dictionary of [Text, Text];
        TaglineToken: JsonToken;
        ParagraphToken: JsonToken;
        BriefToken: JsonToken;
        Result: Text;
        EncodedNewlineTok: Label '<br />', Locked = true;
        NewLineChar: Char;
    begin
        NewLineChar := 10;
        case TextFormat of
            TextFormat::TaglineParagraph:
                begin
                    Arguments.Get('tagline', TaglineToken);
                    Arguments.Get('paragraph', ParagraphToken);
                    Result := TaglineToken.AsValue().AsText() + EncodedNewlineTok + EncodedNewlineTok + ParagraphToken.AsValue().AsText();
                    Result := Result.Replace(NewLineChar, EncodedNewlineTok);
                end;
            TextFormat::Paragraph:
                begin
                    Arguments.Get('paragraph', ParagraphToken);
                    Result := ParagraphToken.AsValue().AsText().Replace(NewLineChar, EncodedNewlineTok);
                end;
            TextFormat::Tagline:
                begin
                    Arguments.Get('tagline', TaglineToken);
                    Result := TaglineToken.AsValue().AsText().Replace(NewLineChar, EncodedNewlineTok);
                end;
            TextFormat::Brief:
                begin
                    Arguments.Get('brief-ad', BriefToken);
                    Result := BriefToken.AsValue().AsText().Replace(NewLineChar, EncodedNewlineTok);
                end;
        end;
        FeatureTelemetryCD.Add('Text Format', TextFormat.Names.Get(TextFormat.Ordinals.IndexOf(TextFormat.AsInteger())));
        FeatureTelemetry.LogUsage('0000N58', EntityTextImpl.GetFeatureName(), 'function_call: generate_product_marketing_ad', FeatureTelemetryCD);
        exit(Result);
    end;

    procedure GetName(): Text
    begin
        exit(FunctionNameLbl);
    end;

    procedure SetTextFormat(Format: Enum "Entity Text Format")
    begin
        TextFormat := Format;
    end;
}