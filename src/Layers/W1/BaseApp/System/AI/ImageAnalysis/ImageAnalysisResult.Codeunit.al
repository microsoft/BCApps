namespace System.AI;

#if not CLEAN30
using System.Text;
#endif

codeunit 2021 "Image Analysis Result"
{
    var
        Result: JsonObject;
        Tags: JsonArray;
        Color: JsonObject;
        DominantColors: JsonArray;
        LastAnalysisTypes: List of [Enum "Image Analysis Type"];

#if not CLEAN30
    [Obsolete('Use SetResult with the native JsonObject type instead.', '30.0')]
    procedure SetResult(InputJSONManagement: Codeunit "JSON Management"; AnalysisType: Enum "Image Analysis Type")
    var
        AnalysisTypes: List of [Enum "Image Analysis Type"];
    begin
        AnalysisTypes.Add(AnalysisType);
        SetResult(InputJSONManagement, AnalysisTypes);
    end;

    [Obsolete('Use SetResult with the native JsonObject type instead.', '30.0')]
    procedure SetResult(InputJSONManagement: Codeunit "JSON Management"; AnalysisTypes: List of [Enum "Image Analysis Type"])
    var
        InputResult: JsonObject;
        ResultText: Text;
    begin
        ResultText := InputJSONManagement.WriteObjectToString();
        if ResultText <> '' then
            InputResult.ReadFrom(ResultText);
        SetResult(InputResult, AnalysisTypes);
    end;
#endif

    procedure SetResult(InputResult: JsonObject; AnalysisType: Enum "Image Analysis Type")
    var
        AnalysisTypes: List of [Enum "Image Analysis Type"];
    begin
        AnalysisTypes.Add(AnalysisType);
        SetResult(InputResult, AnalysisTypes);
    end;

    procedure SetResult(InputResult: JsonObject; AnalysisTypes: List of [Enum "Image Analysis Type"])
    var
        JsonToken: JsonToken;
    begin
        Clear(Tags);
        Clear(Color);
        Clear(DominantColors);

        LastAnalysisTypes := AnalysisTypes;

        Result := InputResult.Clone().AsObject();
        if Result.Keys().Count() = 0 then
            exit;

        if Result.Get('tags', JsonToken) and JsonToken.IsArray() then
            Tags := JsonToken.AsArray()
        else
            if Result.Get('Predictions', JsonToken) and JsonToken.IsArray() then
                Tags := JsonToken.AsArray()
            else
                if Result.Get('predictions', JsonToken) and JsonToken.IsArray() then
                    Tags := JsonToken.AsArray();

        if Result.Get('color', JsonToken) and JsonToken.IsObject() then begin
            Color := JsonToken.AsObject();
            if Color.Get('dominantColors', JsonToken) and JsonToken.IsArray() then
                DominantColors := JsonToken.AsArray();
        end;
    end;

    internal procedure GetResultVerbatim() ResultVerbatim: Text
    begin
        if Result.Keys().Count() = 0 then
            exit('');

        Result.WriteTo(ResultVerbatim);
    end;

    procedure TagCount(): Integer
    begin
        exit(Tags.Count());
    end;

    procedure TagName(Number: Integer): Text
    var
        Tag: JsonObject;
        JsonToken: JsonToken;
        Name: Text;
    begin
        if Tags.Get(Number - 1, JsonToken) and JsonToken.IsObject() then begin
            Tag := JsonToken.AsObject();
            if not TryGetJsonText(Tag, 'name', Name) then
                if not TryGetJsonText(Tag, 'Tag', Name) then
                    TryGetJsonText(Tag, 'tagName', Name);
            exit(Name)
        end;
    end;

    procedure TagConfidence(Number: Integer): Decimal
    var
        Tag: JsonObject;
        JsonToken: JsonToken;
        Confidence: Decimal;
    begin
        if Tags.Get(Number - 1, JsonToken) and JsonToken.IsObject() then begin
            Tag := JsonToken.AsObject();
            if not TryGetJsonDecimal(Tag, 'confidence', Confidence) then
                if not TryGetJsonDecimal(Tag, 'Probability', Confidence) then
                    if not TryGetJsonDecimal(Tag, 'probability', Confidence) then
                        exit(0);
            exit(Confidence)
        end;
    end;

    procedure DominantColorForeground(): Text
    var
        ColorText: Text;
    begin
        TryGetJsonText(Color, 'dominantColorForeground', ColorText);
        exit(ColorText);
    end;

    procedure DominantColorBackground(): Text
    var
        ColorText: Text;
    begin
        TryGetJsonText(Color, 'dominantColorBackground', ColorText);
        exit(ColorText);
    end;

    procedure DominantColorCount(): Integer
    begin
        exit(DominantColors.Count());
    end;

    procedure DominantColor(Number: Integer): Text
    var
        JsonToken: JsonToken;
    begin
        if DominantColors.Get(Number - 1, JsonToken) and JsonToken.IsValue() then begin
            if JsonToken.AsValue().IsNull() or JsonToken.AsValue().IsUndefined() then
                exit('');
            exit(JsonToken.AsValue().AsText());
        end;
    end;

    local procedure TryGetJsonText(JsonObject: JsonObject; PropertyName: Text; var Value: Text): Boolean
    var
        JsonToken: JsonToken;
    begin
        Clear(Value);
        if not JsonObject.Get(PropertyName, JsonToken) or not JsonToken.IsValue() then
            exit(false);
        if JsonToken.AsValue().IsNull() or JsonToken.AsValue().IsUndefined() then
            exit(true);
        Value := JsonToken.AsValue().AsText();
        exit(true);
    end;

    local procedure TryGetJsonDecimal(JsonObject: JsonObject; PropertyName: Text; var Value: Decimal): Boolean
    var
        JsonToken: JsonToken;
    begin
        Clear(Value);
        if not JsonObject.Get(PropertyName, JsonToken) then
            exit(false);
        if not JsonToken.IsValue() then
            exit(false);
        if JsonToken.AsValue().IsNull() or JsonToken.AsValue().IsUndefined() then
            exit(false);
        exit(Evaluate(Value, JsonToken.AsValue().AsText(), 9));
    end;

    procedure GetLatestImageAnalysisTypes(var AnalysisType: List of [Enum "Image Analysis Type"])
    begin
        AnalysisType := LastAnalysisTypes;
    end;
}