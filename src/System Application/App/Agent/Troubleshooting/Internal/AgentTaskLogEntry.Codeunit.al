// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;
using System.Environment;
using System.Security.AccessControl;
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

    procedure ExportToJson(var SelectedAgentTaskLogEntry: Record "Agent Task Log Entry"; var ExportOutStream: OutStream)
    var
        FeatureAccessManagement: Codeunit "Feature Access Management";
        AgentSystemPermissionsImpl: Codeunit "Agent System Permissions Impl.";
        ExportRoot: JsonObject;
        Entries: JsonArray;
        IncludeSerializedPage: Boolean;
    begin
        FeatureAccessManagement.AgentManagementAllowed(true);
        IncludeSerializedPage := AgentSystemPermissionsImpl.CurrentUserHasTroubleshootAllAgents();

        if SelectedAgentTaskLogEntry.FindSet() then
            repeat
                Entries.Add(BuildEntryJson(SelectedAgentTaskLogEntry, IncludeSerializedPage));
            until SelectedAgentTaskLogEntry.Next() = 0;

        ExportRoot.Add(FormatVersionLbl, FormatVersionTok);
        ExportRoot.Add(EntriesLbl, Entries);
        ExportRoot.WriteTo(ExportOutStream);
    end;

    procedure IsAgentAction(AgentTaskLogEntry: Record "Agent Task Log Entry"): Boolean
    var
        User: Record User;
    begin
        case AgentTaskLogEntry.Type of
            AgentTaskLogEntry.Type::"Input Message",
            AgentTaskLogEntry.Type::Resume,
            AgentTaskLogEntry.Type::"User Intervention":
                exit(false);
            AgentTaskLogEntry.Type::"Page Operation",
            AgentTaskLogEntry.Type::"Output Message",
            AgentTaskLogEntry.Type::"Output Message Draft",
            AgentTaskLogEntry.Type::"User Intervention Request":
                exit(true);
            AgentTaskLogEntry.Type::Stop:
                exit(User.Get(AgentTaskLogEntry."User Security ID") and (User."License Type" = User."License Type"::Agent));
        end;

        exit(false);
    end;

    procedure GetAgentName(AgentTaskLogEntry: Record "Agent Task Log Entry"): Text
    var
        Agent: Record Agent;
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        if AgentTaskImpl.TryGetAgentRecordFromTaskId(AgentTaskLogEntry."Task ID", Agent) then
            exit(Agent."Display Name");

        exit('');
    end;

    procedure TryGetSuccess(MemoryEntryDetailsTxt: Text; var Success: Boolean): Boolean
    var
        Root: JsonObject;
    begin
        if not Root.ReadFrom(MemoryEntryDetailsTxt) then
            exit(false);
        if not Root.Contains(SuccessLbl) then
            exit(false);

        Success := Root.GetBoolean(SuccessLbl, true);
        exit(true);
    end;

    procedure GetDecisionPoint(ContextRoot: JsonObject): Boolean
    begin
        if ContextRoot.Contains(IsDecisionPointLbl) then
            exit(ContextRoot.GetBoolean(IsDecisionPointLbl, true));

        exit(false);
    end;

    procedure ReadContextWithFallback(AgentTaskLogEntry: Record "Agent Task Log Entry"; AgentTaskMemoryEntry: Record "Agent Task Memory Entry"; var ContextSource: Text): Text
    var
        ContextTxt: Text;
    begin
        ContextTxt := ReadContext(AgentTaskLogEntry);
        if ContextTxt <> '' then begin
            ContextSource := LogEntryContextSourceTok;
            exit(ContextTxt);
        end;

        ContextTxt := ReadContext(AgentTaskMemoryEntry);
        if ContextTxt <> '' then
            ContextSource := MemoryEntryContextSourceTok
        else
            ContextSource := NoContextSourceTok;

        exit(ContextTxt);
    end;

    local procedure BuildEntryJson(AgentTaskLogEntry: Record "Agent Task Log Entry"; IncludeSerializedPage: Boolean): JsonObject
    var
        AgentTaskMemoryEntry: Record "Agent Task Memory Entry";
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        EntryJson: JsonObject;
        ContextJson: JsonObject;
        MemoryJson: JsonObject;
        Success: Boolean;
        HasSuccess: Boolean;
        MemoryDetailsTxt: Text;
        ContextTxt: Text;
        ContextSource: Text;
    begin
        EntryJson.Add(IdLbl, AgentTaskLogEntry.ID);
        EntryJson.Add(TaskIdLbl, Format(AgentTaskLogEntry."Task ID", 0, 9));
        EntryJson.Add(MemoryEntryIdLbl, AgentTaskLogEntry."Memory Entry ID");
        EntryJson.Add(TypeLbl, Format(AgentTaskLogEntry.Type, 0, 9));
        EntryJson.Add(LevelLbl, Format(AgentTaskLogEntry.Level, 0, 9));
        EntryJson.Add(TimestampLbl, Format(AgentTaskLogEntry.SystemCreatedAt, 0, 9));
        EntryJson.Add(UserFullNameLbl, AgentTaskLogEntry."User Full Name");
        EntryJson.Add(UserSecurityIdLbl, Format(AgentTaskLogEntry."User Security ID", 0, 9));
        EntryJson.Add(PageCaptionLbl, AgentTaskLogEntry."Page Caption");
        EntryJson.Add(DescriptionLbl, AgentTaskLogEntry.Description);
        EntryJson.Add(ReasonLbl, AgentTaskLogEntry.Reason);
        EntryJson.Add(DetailsLbl, AgentTaskImpl.GetDetailsForAgentTaskLogEntry(AgentTaskLogEntry));
        EntryJson.Add(AgentActionLbl, IsAgentAction(AgentTaskLogEntry));
        EntryJson.Add(AgentNameLbl, GetAgentName(AgentTaskLogEntry));

        if AgentTaskMemoryEntry.Get(AgentTaskLogEntry."Task ID", AgentTaskLogEntry."Memory Entry ID") then begin
            MemoryDetailsTxt := ReadMemoryEntryDetails(AgentTaskMemoryEntry);
            MemoryJson.Add(IdLbl, AgentTaskMemoryEntry.ID);
            MemoryJson.Add(DetailsLbl, MemoryDetailsTxt);
            ContextTxt := ReadContextWithFallback(AgentTaskLogEntry, AgentTaskMemoryEntry, ContextSource);
        end else begin
            MemoryJson.Add(IdLbl, AgentTaskLogEntry."Memory Entry ID");
            MemoryJson.Add(DetailsLbl, '');
            ContextTxt := ReadContext(AgentTaskLogEntry);
            if ContextTxt = '' then
                ContextSource := NoContextSourceTok
            else
                ContextSource := LogEntryContextSourceTok;
        end;

        HasSuccess := TryGetSuccess(MemoryDetailsTxt, Success);
        AddNullableBoolean(EntryJson, SuccessLbl, HasSuccess, Success);
        BuildContextJson(ContextTxt, ContextSource, IncludeSerializedPage, ContextJson);
        EntryJson.Add(DecisionPointLbl, ContextJson.GetBoolean(DecisionPointLbl, true));
        EntryJson.Add(MemoryLbl, MemoryJson);
        EntryJson.Add(ContextLbl, ContextJson);
        EntryJson.Add(TaskContextLbl, BuildTaskContextJson(AgentTaskLogEntry));
        EntryJson.Add(MessagesLbl, BuildMessagesJson(AgentTaskLogEntry));
        EntryJson.Add(SiblingActionsLbl, BuildSiblingActionsJson(AgentTaskLogEntry));

        exit(EntryJson);
    end;

    local procedure ReadMemoryEntryDetails(AgentTaskMemoryEntry: Record "Agent Task Memory Entry") MemoryDetailsTxt: Text
    var
        ContentInStream: InStream;
    begin
        AgentTaskMemoryEntry.CalcFields(Details);
        AgentTaskMemoryEntry.Details.CreateInStream(ContentInStream, GetDefaultEncoding());
        ContentInStream.Read(MemoryDetailsTxt);
    end;

    procedure BuildContextJson(ContextTxt: Text; ContextSource: Text; IncludeSerializedPage: Boolean; var ContextJson: JsonObject)
    var
        ContextRoot: JsonObject;
        JsonToken: JsonToken;
        EmptyPageStack: JsonArray;
        EmptyAvailableTools: JsonArray;
        EmptyMemorizedData: JsonObject;
        EmptyTaskPageSettings: JsonObject;
        RawSerializedPageJson: Text;
    begin
        Clear(ContextJson);
        ContextJson.Add(SourceLbl, ContextSource);
        ContextJson.Add(ValidLbl, false);
        ContextJson.Add(DecisionPointLbl, false);
        ContextJson.Add(SerializedPageIncludedLbl, false);
        ContextJson.Add(SerializedPageRedactedLbl, false);
        ContextJson.Add(ExportPageStackLbl, EmptyPageStack);
        ContextJson.Add(AvailableToolsLbl, EmptyAvailableTools);
        ContextJson.Add(MemorizedDataLbl, EmptyMemorizedData);
        ContextJson.Add(TaskPageSettingsLbl, EmptyTaskPageSettings);

        if (ContextTxt = '') or not ContextRoot.ReadFrom(ContextTxt) then
            exit;

        ContextJson.Replace(ValidLbl, true);
        ContextJson.Replace(DecisionPointLbl, GetDecisionPoint(ContextRoot));
        ContextJson.Replace(ExportPageStackLbl, BuildPageStackJson(ContextRoot));
        ReplaceContextToken(ContextJson, ContextRoot, AvailableToolsLbl, AvailableToolsLbl, true);
        ReplaceContextToken(ContextJson, ContextRoot, MemorizedDataLbl, MemorizedDataLbl, false);
        ContextJson.Replace(TaskPageSettingsLbl, BuildTaskPageSettingsJson(ContextRoot));

        RawSerializedPageJson := ContextRoot.GetText(SerializedPageLbl, true);
        if RawSerializedPageJson = '' then
            exit;

        if not IncludeSerializedPage then begin
            ContextJson.Replace(SerializedPageRedactedLbl, true);
            ContextJson.Add(SerializedPageRedactionReasonLbl, AgentTroubleshooterMissingPermissionTxt);
            exit;
        end;

        ContextJson.Replace(SerializedPageIncludedLbl, true);
        if JsonToken.ReadFrom(RawSerializedPageJson) then
            ContextJson.Add(SerializedPageLbl, JsonToken)
        else
            ContextJson.Add(SerializedPageLbl, RawSerializedPageJson);
    end;

    local procedure BuildPageStackJson(ContextRoot: JsonObject): JsonArray
    var
        PageStack: JsonArray;
        ExportPageStack: JsonArray;
        PageToken: JsonToken;
        Index: Integer;
    begin
        PageStack := ContextRoot.GetArray(PagestackLbl, true);
        for Index := PageStack.Count() - 1 downto 0 do begin
            PageStack.Get(Index, PageToken);
            if not PageToken.AsValue().IsNull() then
                ExportPageStack.Add(PageToken.AsValue().AsText());
        end;

        exit(ExportPageStack);
    end;

    local procedure BuildTaskPageSettingsJson(ContextRoot: JsonObject): JsonObject
    var
        TaskPageContext: JsonObject;
        CommunicationCulture: JsonObject;
        TaskPageSettings: JsonObject;
    begin
        if not ContextRoot.Contains(TaskPageContextLbl) then
            exit(TaskPageSettings);

        TaskPageContext := ContextRoot.GetObject(TaskPageContextLbl, true);
        TaskPageSettings.Add(CurrencyCodeLbl, TaskPageContext.GetText(CurrencyCodeLbl, true));
        TaskPageSettings.Add(CurrencySymbolLbl, TaskPageContext.GetText(CurrencySymbolLbl, true));

        if not TaskPageContext.Contains(OutgoingCommunicationCultureLbl) then
            exit(TaskPageSettings);

        CommunicationCulture := TaskPageContext.GetObject(OutgoingCommunicationCultureLbl, true);
        TaskPageSettings.Add(CommunicationLanguageLbl, CommunicationCulture.GetText(CommunicationLanguageSourceLbl, true));
        TaskPageSettings.Add(CommunicationDateFormatLbl, CommunicationCulture.GetText(CommunicationDateFormatSourceLbl, true));
        TaskPageSettings.Add(CommunicationTimeFormatLbl, CommunicationCulture.GetText(CommunicationTimeFormatSourceLbl, true));
        TaskPageSettings.Add(CommunicationFormattedNumberExampleLbl, CommunicationCulture.GetText(CommunicationFormattedNumberExampleSourceLbl, true));
        exit(TaskPageSettings);
    end;

    local procedure ReplaceContextToken(var ContextJson: JsonObject; ContextRoot: JsonObject; SourcePropertyName: Text; TargetPropertyName: Text; ExpectArray: Boolean)
    var
        JsonToken: JsonToken;
    begin
        if not ContextRoot.Get(SourcePropertyName, JsonToken) then
            exit;
        if ExpectArray and not JsonToken.IsArray() then
            exit;
        if not ExpectArray and not JsonToken.IsObject() then
            exit;

        ContextJson.Replace(TargetPropertyName, JsonToken);
    end;

    local procedure BuildTaskContextJson(AgentTaskLogEntry: Record "Agent Task Log Entry"): JsonObject
    var
        AgentTask: Record "Agent Task";
        TaskContextJson: JsonObject;
    begin
        TaskContextJson.Add(TaskIdLbl, Format(AgentTaskLogEntry."Task ID", 0, 9));
        TaskContextJson.Add(AgentNameLbl, '');
        TaskContextJson.Add(TaskTitleLbl, '');
        TaskContextJson.Add(CompanyNameLbl, '');

        if not AgentTask.Get(AgentTaskLogEntry."Task ID") then
            exit(TaskContextJson);

        AgentTask.CalcFields("Agent Display Name");
        TaskContextJson.Replace(AgentNameLbl, AgentTask."Agent Display Name");
        TaskContextJson.Replace(TaskTitleLbl, AgentTask.Title);
        TaskContextJson.Replace(CompanyNameLbl, AgentTask."Company Name");
        exit(TaskContextJson);
    end;

    local procedure BuildMessagesJson(AgentTaskLogEntry: Record "Agent Task Log Entry"): JsonObject
    var
        MessagesJson: JsonObject;
    begin
        MessagesJson.Add(InputLbl, BuildMessageArray(AgentTaskLogEntry, true, false));
        MessagesJson.Add(OutputLbl, BuildMessageArray(AgentTaskLogEntry, false, false));
        MessagesJson.Add(EarlierLbl, BuildMessageArray(AgentTaskLogEntry, false, true));
        exit(MessagesJson);
    end;

    local procedure BuildMessageArray(AgentTaskLogEntry: Record "Agent Task Log Entry"; InputMessages: Boolean; EarlierMessages: Boolean): JsonArray
    var
        AgentTaskMessage: Record "Agent Task Message";
        Messages: JsonArray;
    begin
        AgentTaskMessage.SetRange("Task ID", AgentTaskLogEntry."Task ID");
        if EarlierMessages then
            AgentTaskMessage.SetFilter("Memory Entry ID", '<%1', AgentTaskLogEntry."Memory Entry ID")
        else begin
            AgentTaskMessage.SetRange("Memory Entry ID", AgentTaskLogEntry."Memory Entry ID");
            if InputMessages then
                AgentTaskMessage.SetRange(Type, AgentTaskMessage.Type::Input)
            else
                AgentTaskMessage.SetRange(Type, AgentTaskMessage.Type::Output);
        end;

        AgentTaskMessage.SetCurrentKey("Memory Entry ID");
        AgentTaskMessage.Ascending(false);
        if AgentTaskMessage.FindSet() then
            repeat
                Messages.Add(BuildMessageJson(AgentTaskMessage));
            until AgentTaskMessage.Next() = 0;

        exit(Messages);
    end;

    local procedure BuildMessageJson(AgentTaskMessage: Record "Agent Task Message"): JsonObject
    var
        AgentMessage: Codeunit "Agent Message";
        MessageJson: JsonObject;
    begin
        MessageJson.Add(IdLbl, Format(AgentTaskMessage.ID, 0, 9));
        MessageJson.Add(MemoryEntryIdLbl, AgentTaskMessage."Memory Entry ID");
        MessageJson.Add(TypeLbl, Format(AgentTaskMessage.Type, 0, 9));
        MessageJson.Add(StatusLbl, Format(AgentTaskMessage.Status, 0, 9));
        MessageJson.Add(CreatedAtLbl, Format(AgentTaskMessage.SystemCreatedAt, 0, 9));
        MessageJson.Add(ModifiedAtLbl, Format(AgentTaskMessage.SystemModifiedAt, 0, 9));
        MessageJson.Add(CreatedByFullNameLbl, AgentTaskMessage."Created By Full Name");
        MessageJson.Add(MessageLbl, AgentMessage.GetText(AgentTaskMessage));
        exit(MessageJson);
    end;

    local procedure BuildSiblingActionsJson(AgentTaskLogEntry: Record "Agent Task Log Entry"): JsonArray
    var
        SiblingLogEntry: Record "Agent Task Log Entry";
        SiblingActions: JsonArray;
    begin
        SiblingLogEntry.SetRange("Task ID", AgentTaskLogEntry."Task ID");
        SiblingLogEntry.SetRange("Memory Entry ID", AgentTaskLogEntry."Memory Entry ID");
        SiblingLogEntry.SetFilter(ID, '<>%1', AgentTaskLogEntry.ID);
        SiblingLogEntry.SetCurrentKey(ID);
        SiblingLogEntry.Ascending(false);
        if SiblingLogEntry.FindSet() then
            repeat
                SiblingActions.Add(BuildSiblingActionJson(SiblingLogEntry));
            until SiblingLogEntry.Next() = 0;

        exit(SiblingActions);
    end;

    local procedure BuildSiblingActionJson(SiblingLogEntry: Record "Agent Task Log Entry"): JsonObject
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        SiblingActionJson: JsonObject;
    begin
        SiblingActionJson.Add(IdLbl, SiblingLogEntry.ID);
        SiblingActionJson.Add(TypeLbl, Format(SiblingLogEntry.Type, 0, 9));
        SiblingActionJson.Add(LevelLbl, Format(SiblingLogEntry.Level, 0, 9));
        SiblingActionJson.Add(DescriptionLbl, SiblingLogEntry.Description);
        SiblingActionJson.Add(ReasonLbl, SiblingLogEntry.Reason);
        SiblingActionJson.Add(DetailsLbl, AgentTaskImpl.GetDetailsForAgentTaskLogEntry(SiblingLogEntry));
        SiblingActionJson.Add(PageCaptionLbl, SiblingLogEntry."Page Caption");
        SiblingActionJson.Add(UserFullNameLbl, SiblingLogEntry."User Full Name");
        SiblingActionJson.Add(TimestampLbl, Format(SiblingLogEntry.SystemCreatedAt, 0, 9));
        exit(SiblingActionJson);
    end;

    local procedure AddNullableBoolean(var JsonObject: JsonObject; PropertyName: Text; HasValue: Boolean; Value: Boolean)
    var
        NullToken: JsonToken;
    begin
        if HasValue then begin
            JsonObject.Add(PropertyName, Value);
            exit;
        end;

        NullToken.ReadFrom(NullJsonTok);
        JsonObject.Add(PropertyName, NullToken);
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
        AgentTroubleshooterMissingPermissionTxt: Label 'Only users who are assigned the ''Troubleshoot All Agents'' permission can view page snapshot data.';
        FormatVersionLbl: Label 'formatVersion', Locked = true;
        FormatVersionTok: Label '1.0', Locked = true;
        EntriesLbl: Label 'entries', Locked = true;
        IdLbl: Label 'id', Locked = true;
        TaskIdLbl: Label 'taskId', Locked = true;
        MemoryEntryIdLbl: Label 'memoryEntryId', Locked = true;
        TypeLbl: Label 'type', Locked = true;
        LevelLbl: Label 'level', Locked = true;
        TimestampLbl: Label 'timestamp', Locked = true;
        CreatedAtLbl: Label 'createdAt', Locked = true;
        ModifiedAtLbl: Label 'modifiedAt', Locked = true;
        UserFullNameLbl: Label 'userFullName', Locked = true;
        UserSecurityIdLbl: Label 'userSecurityId', Locked = true;
        CreatedByFullNameLbl: Label 'createdByFullName', Locked = true;
        PageCaptionLbl: Label 'pageCaption', Locked = true;
        DescriptionLbl: Label 'description', Locked = true;
        ReasonLbl: Label 'reason', Locked = true;
        DetailsLbl: Label 'details', Locked = true;
        AgentActionLbl: Label 'agentAction', Locked = true;
        AgentNameLbl: Label 'agentName', Locked = true;
        SuccessLbl: Label 'success', Locked = true;
        DecisionPointLbl: Label 'decisionPoint', Locked = true;
        MemoryLbl: Label 'memory', Locked = true;
        ContextLbl: Label 'context', Locked = true;
        TaskContextLbl: Label 'taskContext', Locked = true;
        SourceLbl: Label 'source', Locked = true;
        ValidLbl: Label 'valid', Locked = true;
        LogEntryContextSourceTok: Label 'logEntry', Locked = true;
        MemoryEntryContextSourceTok: Label 'memoryEntry', Locked = true;
        NoContextSourceTok: Label 'none', Locked = true;
        SerializedPageIncludedLbl: Label 'serializedPageIncluded', Locked = true;
        SerializedPageRedactedLbl: Label 'serializedPageRedacted', Locked = true;
        SerializedPageRedactionReasonLbl: Label 'serializedPageRedactionReason', Locked = true;
        ExportPageStackLbl: Label 'pageStack', Locked = true;
        TaskPageSettingsLbl: Label 'taskPageSettings', Locked = true;
        CurrencyCodeLbl: Label 'currencyCode', Locked = true;
        CurrencySymbolLbl: Label 'currencySymbol', Locked = true;
        OutgoingCommunicationCultureLbl: Label 'outgoingCommunicationCulture', Locked = true;
        CommunicationLanguageLbl: Label 'communicationLanguage', Locked = true;
        CommunicationDateFormatLbl: Label 'communicationDateFormat', Locked = true;
        CommunicationTimeFormatLbl: Label 'communicationTimeFormat', Locked = true;
        CommunicationFormattedNumberExampleLbl: Label 'communicationFormattedNumberExample', Locked = true;
        CommunicationLanguageSourceLbl: Label 'language', Locked = true;
        CommunicationDateFormatSourceLbl: Label 'dateFormat', Locked = true;
        CommunicationTimeFormatSourceLbl: Label 'timeFormat', Locked = true;
        CommunicationFormattedNumberExampleSourceLbl: Label 'formattedNumberExample', Locked = true;
        TaskTitleLbl: Label 'taskTitle', Locked = true;
        CompanyNameLbl: Label 'companyName', Locked = true;
        MessagesLbl: Label 'messages', Locked = true;
        InputLbl: Label 'input', Locked = true;
        OutputLbl: Label 'output', Locked = true;
        EarlierLbl: Label 'earlier', Locked = true;
        MessageLbl: Label 'message', Locked = true;
        StatusLbl: Label 'status', Locked = true;
        SiblingActionsLbl: Label 'siblingActions', Locked = true;
        SerializedPageLbl: Label 'serializedPage', Locked = true;
        IsDecisionPointLbl: Label 'isDecisionPoint', Locked = true;
        TaskPageContextLbl: Label 'taskPageContext', Locked = true;
        NullJsonTok: Label 'null', Locked = true;
}