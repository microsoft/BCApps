// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;

codeunit 4314 "Agent Task Log Entry"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure FormatJsonTextForRichContent(JsonText: text): text
    var
        Json: Codeunit System.Text.Json.Json;
        FormattedJson: Text;
    begin
        json.InitializeCollection('[' + JsonText + ']');
        FormattedJson := json.GetCollectionAsText(true);
        if StrLen(FormattedJson) < 5 then
            exit('<pre>' + JsonText + '</pre>');
        FormattedJson := FormattedJson.Substring(4, StrLen(FormattedJson) - 4);
        FormattedJson := '<pre>' + FormattedJson + '</pre>';
        exit(FormattedJson);
    end;

    procedure ExtractPageStack(var PageStacksRecords: Record "Agent JSON Buffer" temporary; ContextRootObject: JsonObject)
    var
        StackArray: JsonArray;
        JsonText: JsonToken;
        Index: Integer;
        Count: Integer;
    begin
        PageStacksRecords.DeleteAll();
        StackArray := ContextRootObject.GetArray(PagestackLbl, true);
        Count := StackArray.Count;
        for Index := 0 to Count - 1 do begin
            StackArray.Get(Count - index - 1, JsonText);
            if JsonText.AsValue().IsNull() then
                // Skip null values, nothing to show
                continue;

            PageStacksRecords.Id := index + 1;
            PageStacksRecords.Insert();
            PageStacksRecords.SetJsonText(JsonText.AsValue().AsText());
        end;
    end;

    procedure ExtractAvailableTools(var AvailableToolsRecords: Record "Agent JSON Buffer" temporary; ContextRootObject: JsonObject)
    var
        AvailableToolsArray: JsonArray;
        JsonText: JsonToken;
        Index: Integer;
    begin
        AvailableToolsRecords.DeleteAll();
        AvailableToolsArray := ContextRootObject.GetArray(AvailableToolsLbl, true);
        foreach JsonText in AvailableToolsArray do begin
            Index += 1;
            AvailableToolsRecords.Id := Index;
            AvailableToolsRecords.Insert();
            AvailableToolsRecords.SetJsonText(JsonText.AsValue().AsText());
        end;
    end;

    procedure ExtractMemorizedData(var MemorizedDataRecords: Record "Agent JSON Buffer" temporary; ContextRootObject: JsonObject)
    var
        JKey: Text;
        JValue: JsonToken;
        NewRow: JsonObject;
        JObject: JsonObject;
    begin
        if not ContextRootObject.Get(MemorizedDataLbl, JValue) then
            exit;

        MemorizedDataRecords.DeleteAll();
        JObject := JValue.AsObject();
        foreach JKey in JObject.Keys() do begin
            MemorizedDataRecords.Id += 1;
            Clear(NewRow);
            NewRow.Add(KeyLbl, JKey);
            JObject.Get(JKey, JValue);

            NewRow.Add(ValueLbl, JValue.AsValue().AsText());
            MemorizedDataRecords.Insert();
            MemorizedDataRecords.SetJson(NewRow);
        end;
    end;

    procedure ReadContext(Entry: Record "Agent Task Memory Entry") ContextTxt: Text;
    var
        ContentInStream: InStream;
    begin
#pragma warning disable AL0432
        Entry.CalcFields(Entry.Context);
        Entry.Context.CreateInStream(ContentInStream, GetDefaultEncoding());
        ContentInStream.ReadText(ContextTxt);
#pragma warning restore AL0432
    end;

    procedure ReadContext(Entry: Record "Agent Task Log Entry") ContextTxt: Text;
    var
        ContentInStream: InStream;
    begin
        Entry.CalcFields(Entry."Troubleshooting Info");
        Entry."Troubleshooting Info".CreateInStream(ContentInStream, GetDefaultEncoding());
        ContentInStream.ReadText(ContextTxt);
    end;

    procedure GetDefaultEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    var
        PagestackLbl: Label 'pageStack', Locked = true;
        AvailableToolsLbl: Label 'availableTools', Locked = true;
        MemorizedDataLbl: Label 'memorizedData', Locked = true;
        KeyLbl: Label 'key', Locked = true;
        ValueLbl: Label 'value', Locked = true;
}