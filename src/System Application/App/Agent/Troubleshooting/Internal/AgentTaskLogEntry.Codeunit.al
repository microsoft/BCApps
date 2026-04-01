// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;
using System.Environment;
using System.Text.Json;

codeunit 4314 "Agent Task Log Entry"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure FormatJsonTextForRichContent(JsonText: text): text
    var
        Json: Codeunit Json;
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", OnFeedbackEvent, '', false, false)]
    local procedure OnFeedbackEventForAgentTaskLogEntryTable(PageId: Integer; Context: Dictionary of [Text, Text]; var Handled: Boolean)
    var
        AgentRecord: Record Agent;
        AgentTaskLogEntryRecord: Record "Agent Task Log Entry";
        AgentUserFeedback: Codeunit "Agent User Feedback";
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        TableIndex: Integer;
        SystemIdGuid: Guid;
    begin
        if not TryFindSourceTableIdIndex(Context, Database::"Agent Task Log Entry", TableIndex) then
            exit;

        if not TryGetSystemIdAtIndex(Context, TableIndex, SystemIdGuid) then
            exit;

        if not AgentTaskLogEntryRecord.GetBySystemId(SystemIdGuid) then
            exit;

        // Record is now initialized and can be used for enriching the context
        if not AgentTaskImpl.TryGetAgentRecordFromTaskId(AgentTaskLogEntryRecord."Task ID", AgentRecord) then
            exit;

        Context.Add(AgentUserFeedback.GetAgentUserSecurityIdTok(), Format(AgentRecord."User Security ID"));
        Context.Add(AgentUserFeedback.GetAgentMetadataProviderTok(), Format(AgentRecord."Agent Metadata Provider"));
        Context.Add(AgentUserFeedback.GetAgentTaskIdTok(), Format(AgentTaskLogEntryRecord."Task ID"));
        Context.Add(AgentUserFeedback.GetAgentTaskLogEntryIdTok(), Format(AgentTaskLogEntryRecord.ID));
        Context.Add(AgentUserFeedback.GetAgentTaskLogEntryTypeTok(), Format(AgentTaskLogEntryRecord.Type));
    end;

    local procedure TryFindSourceTableIdIndex(Context: Dictionary of [Text, Text]; TargetTableId: Integer; var Index: Integer): Boolean
    var
        TableIdList: List of [Text];
        TableIdText: Text;
        CandidateTableId: Integer;
        SourceTableIDsTok: Label 'SourceTableIDs', Locked = true;
    begin
        if not Context.ContainsKey(SourceTableIDsTok) then
            exit(false);

        TableIdList := Context.Get(SourceTableIDsTok).Split(',');
        for Index := 1 to TableIdList.Count() do begin
            TableIdText := TableIdList.Get(Index);
            if Evaluate(CandidateTableId, TableIdText.Trim()) then
                if CandidateTableId = TargetTableId then
                    exit(true);
        end;

        exit(false);
    end;

    local procedure TryGetSystemIdAtIndex(Context: Dictionary of [Text, Text]; Index: Integer; var SystemIdGuid: Guid): Boolean
    var
        SystemIdList: List of [Text];
        SystemIdText: Text;
        SystemIDsTok: Label 'SystemIDs', Locked = true;
    begin
        if not Context.ContainsKey(SystemIDsTok) then
            exit(false);

        SystemIdList := Context.Get(SystemIDsTok).Split(',');
        if (Index < 1) or (Index > SystemIdList.Count()) then
            exit(false);

        SystemIdText := SystemIdList.Get(Index);
        exit(Evaluate(SystemIdGuid, SystemIdText.Trim()));
    end;

    var
        PagestackLbl: Label 'pageStack', Locked = true;
        AvailableToolsLbl: Label 'availableTools', Locked = true;
        MemorizedDataLbl: Label 'memorizedData', Locked = true;
        KeyLbl: Label 'key', Locked = true;
        ValueLbl: Label 'value', Locked = true;
}