namespace System.AI;

using System;
using System.Text;

codeunit 2021 "Image Analysis Result"
{
    var
        JSONManagement: Codeunit "JSON Management";
        Result: DotNet JObject;
        Tags: DotNet JArray;
        Color: DotNet JObject;
        DominantColors: DotNet JArray;
        LastAnalysisTypes: List of [Enum "Image Analysis Type"];

    procedure SetResult(InputJSONManagement: Codeunit "JSON Management"; AnalysisType: Enum "Image Analysis Type")
    var
        AnalysisTypes: List of [Enum "Image Analysis Type"];
    begin
        AnalysisTypes.Add(AnalysisType);
        SetResult(InputJSONManagement, AnalysisTypes);
    end;

    procedure SetResult(InputJSONManagement: Codeunit "JSON Management"; AnalysisTypes: List of [Enum "Image Analysis Type"])
    begin
        Tags := Tags.JArray();
        Color := Color.JObject();
        DominantColors := DominantColors.JArray();

        LastAnalysisTypes := AnalysisTypes;

        InputJSONManagement.GetJSONObject(Result);
        if IsNull(Result) then
            exit;

        if not JSONManagement.GetArrayPropertyValueFromJObjectByName(Result, 'tags', Tags) then
            if not JSONManagement.GetArrayPropertyValueFromJObjectByName(Result, 'Predictions', Tags) then
                if not JSONManagement.GetArrayPropertyValueFromJObjectByName(Result, 'predictions', Tags) then
                    Tags := Tags.JArray();

        Color := Color.JObject();
        DominantColors := DominantColors.JArray();
        if JSONManagement.GetObjectPropertyValueFromJObjectByName(Result, 'color', Color) then
            JSONManagement.GetArrayPropertyValueFromJObjectByName(Color, 'dominantColors', DominantColors)
        else begin
            Color := Color.JObject();
            DominantColors := DominantColors.JArray();
        end;
    end;

    internal procedure GetResultVerbatim() ResultVerbatim: Text
    begin
        if IsNull(Result) then
            exit('');

        ResultVerbatim := Result.ToString();
    end;

    procedure TagCount(): Integer
    begin
        exit(Tags.Count);
    end;

    procedure TagName(Number: Integer): Text
    var
        Tag: DotNet JObject;
        Name: Text;
    begin
        JSONManagement.InitializeCollectionFromJArray(Tags);
        if JSONManagement.GetJObjectFromCollectionByIndex(Tag, Number - 1) then begin
            if not JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'name', Name) then
                if not JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'Tag', Name) then
                    JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'tagName', Name);
            exit(Name)
        end;
    end;

    procedure TagConfidence(Number: Integer): Decimal
    var
        Tag: DotNet JObject;
        Confidence: Decimal;
        ConfidenceText: Text;
    begin
        JSONManagement.InitializeCollectionFromJArray(Tags);
        if JSONManagement.GetJObjectFromCollectionByIndex(Tag, Number - 1) then begin
            if not JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'confidence', ConfidenceText) then
                if not JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'Probability', ConfidenceText) then
                    if not JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'probability', ConfidenceText) then
                        ConfidenceText := '0';
            Evaluate(Confidence, ConfidenceText);
            exit(Confidence)
        end;
    end;

    procedure DominantColorForeground(): Text
    var
        ColorText: Text;
    begin
        JSONManagement.GetStringPropertyValueFromJObjectByName(Color, 'dominantColorForeground', ColorText);
        exit(ColorText);
    end;

    procedure DominantColorBackground(): Text
    var
        ColorText: Text;
    begin
        JSONManagement.GetStringPropertyValueFromJObjectByName(Color, 'dominantColorBackground', ColorText);
        exit(ColorText);
    end;

    procedure DominantColorCount(): Integer
    begin
        exit(DominantColors.Count);
    end;

    procedure DominantColor(Number: Integer): Text
    var
        LocalDominantColor: DotNet JObject;
    begin
        JSONManagement.InitializeCollectionFromJArray(DominantColors);
        if JSONManagement.GetJObjectFromCollectionByIndex(LocalDominantColor, Number - 1) then
            exit(Format(LocalDominantColor));
    end;


    procedure GetLatestImageAnalysisTypes(var AnalysisType: List of [Enum "Image Analysis Type"])
    begin
        AnalysisType := LastAnalysisTypes;
    end;
}