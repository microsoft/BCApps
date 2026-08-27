// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;
using System.Environment;

codeunit 4313 "Agent Task Log Export"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

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

    local procedure BuildEntryJson(AgentTaskLogEntryRecord: Record "Agent Task Log Entry"; IncludeSerializedPage: Boolean): JsonObject
    var
        AgentTaskMemoryEntry: Record "Agent Task Memory Entry";
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        EntryJson: JsonObject;
        ContextJson: JsonObject;
        MemoryJson: JsonObject;
        MessagesJson: JsonObject;
        SiblingActions: JsonArray;
        Success: Boolean;
        MemoryDetailsTxt: Text;
        ContextTxt: Text;
        ContextSource: Text;
    begin
        EntryJson.Add(IdLbl, AgentTaskLogEntryRecord.ID);
        EntryJson.Add(TaskIdLbl, Format(AgentTaskLogEntryRecord."Task ID", 0, 9));
        EntryJson.Add(MemoryEntryIdLbl, AgentTaskLogEntryRecord."Memory Entry ID");
        EntryJson.Add(TypeLbl, Format(AgentTaskLogEntryRecord.Type, 0, 9));
        EntryJson.Add(LevelLbl, Format(AgentTaskLogEntryRecord.Level, 0, 9));
        EntryJson.Add(TimestampLbl, Format(AgentTaskLogEntryRecord.SystemCreatedAt, 0, 9));
        EntryJson.Add(UserFullNameLbl, AgentTaskLogEntryRecord."User Full Name");
        EntryJson.Add(UserSecurityIdLbl, Format(AgentTaskLogEntryRecord."User Security ID", 0, 9));
        EntryJson.Add(PageCaptionLbl, AgentTaskLogEntryRecord."Page Caption");
        EntryJson.Add(DescriptionLbl, AgentTaskLogEntryRecord.Description);
        EntryJson.Add(ReasonLbl, AgentTaskLogEntryRecord.Reason);
        EntryJson.Add(DetailsLbl, AgentTaskImpl.GetDetailsForAgentTaskLogEntry(AgentTaskLogEntryRecord));
        EntryJson.Add(AgentActionLbl, AgentTaskLogEntry.IsAgentAction(AgentTaskLogEntryRecord));
        EntryJson.Add(AgentNameLbl, AgentTaskLogEntry.GetAgentName(AgentTaskLogEntryRecord));

        if AgentTaskMemoryEntry.Get(AgentTaskLogEntryRecord."Task ID", AgentTaskLogEntryRecord."Memory Entry ID") then begin
            MemoryDetailsTxt := ReadMemoryEntryDetails(AgentTaskMemoryEntry);
            MemoryJson.Add(IdLbl, AgentTaskMemoryEntry.ID);
            if MemoryDetailsTxt <> '' then
                MemoryJson.Add(DetailsLbl, MemoryDetailsTxt);
            EntryJson.Add(MemoryLbl, MemoryJson);
        end;

        if AgentTaskLogEntry.GetSuccess(MemoryDetailsTxt, Success) then
            EntryJson.Add(SuccessLbl, Success);

        ContextTxt := AgentTaskLogEntry.ReadContextSafe(AgentTaskLogEntryRecord, AgentTaskMemoryEntry, ContextSource);
        BuildContextJson(ContextTxt, ContextSource, IncludeSerializedPage, ContextJson);
        if ContextJson.Contains(DecisionPointLbl) then
            EntryJson.Add(DecisionPointLbl, ContextJson.GetBoolean(DecisionPointLbl));
        if ContextJson.Keys().Count() > 0 then
            EntryJson.Add(ContextLbl, ContextJson);

        EntryJson.Add(TaskContextLbl, BuildTaskContextJson(AgentTaskLogEntryRecord));

        MessagesJson := BuildMessagesJson(AgentTaskLogEntryRecord);
        if MessagesJson.Keys().Count() > 0 then
            EntryJson.Add(MessagesLbl, MessagesJson);

        SiblingActions := BuildSiblingActionsJson(AgentTaskLogEntryRecord);
        if SiblingActions.Count() > 0 then
            EntryJson.Add(SiblingActionsLbl, SiblingActions);

        exit(EntryJson);
    end;

    local procedure ReadMemoryEntryDetails(AgentTaskMemoryEntry: Record "Agent Task Memory Entry") MemoryDetailsTxt: Text
    var
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        ContentInStream: InStream;
    begin
        AgentTaskMemoryEntry.CalcFields(Details);
        AgentTaskMemoryEntry.Details.CreateInStream(ContentInStream, AgentTaskLogEntry.GetDefaultEncoding());
        ContentInStream.Read(MemoryDetailsTxt);
    end;

    procedure BuildContextJson(ContextTxt: Text; ContextSource: Text; IncludeSerializedPage: Boolean; var ContextJson: JsonObject)
    var
        ContextRoot: JsonObject;
        JsonToken: JsonToken;
        PageStack: JsonArray;
        TaskPageSettings: JsonObject;
        RawSerializedPageJson: Text;
    begin
        Clear(ContextJson);
        if (ContextTxt = '') or not ContextRoot.ReadFrom(ContextTxt) then
            exit;

        if ContextSource <> '' then
            ContextJson.Add(SourceLbl, ContextSource);
        if ContextRoot.Contains(IsDecisionPointLbl) then
            ContextJson.Add(DecisionPointLbl, ContextRoot.GetBoolean(IsDecisionPointLbl, true));

        PageStack := BuildPageStackJson(ContextRoot);
        if PageStack.Count() > 0 then
            ContextJson.Add(PageStackLbl, PageStack);

        AddContextToken(ContextJson, ContextRoot, AvailableToolsLbl, true);
        AddContextToken(ContextJson, ContextRoot, MemorizedDataLbl, false);

        TaskPageSettings := BuildTaskPageSettingsJson(ContextRoot);
        if TaskPageSettings.Keys().Count() > 0 then
            ContextJson.Add(TaskPageSettingsLbl, TaskPageSettings);

        RawSerializedPageJson := ContextRoot.GetText(SerializedPageLbl, true);
        if RawSerializedPageJson = '' then
            exit;

        if not IncludeSerializedPage then begin
            ContextJson.Add(SerializedPageRedactedLbl, true);
            ContextJson.Add(SerializedPageRedactionReasonLbl, AgentTroubleshooterMissingPermissionTxt);
            exit;
        end;

        if JsonToken.ReadFrom(RawSerializedPageJson) then
            ContextJson.Add(SerializedPageLbl, JsonToken)
        else
            ContextJson.Add(SerializedPageLbl, RawSerializedPageJson);
    end;

    local procedure BuildPageStackJson(ContextRoot: JsonObject): JsonArray
    var
        PageStack: JsonArray;
        ExportPageStack: JsonArray;
        PageStackEntry: JsonObject;
        PageToken: JsonToken;
        Index: Integer;
        Order: Integer;
    begin
        PageStack := ContextRoot.GetArray(PageStackLbl, true);
        for Index := PageStack.Count() - 1 downto 0 do begin
            PageStack.Get(Index, PageToken);
            if PageToken.AsValue().IsNull() then
                continue;

            Order += 1;
            Clear(PageStackEntry);
            PageStackEntry.Add(OrderLbl, Order);
            PageStackEntry.Add(PageCaptionLbl, PageToken.AsValue().AsText());
            ExportPageStack.Add(PageStackEntry);
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
        AddTextProperty(TaskPageSettings, TaskPageContext, CurrencyCodeLbl, CurrencyCodeLbl);
        AddTextProperty(TaskPageSettings, TaskPageContext, CurrencySymbolLbl, CurrencySymbolLbl);

        if not TaskPageContext.Contains(OutgoingCommunicationCultureLbl) then
            exit(TaskPageSettings);

        CommunicationCulture := TaskPageContext.GetObject(OutgoingCommunicationCultureLbl, true);
        AddTextProperty(TaskPageSettings, CommunicationCulture, CommunicationLanguageSourceLbl, CommunicationLanguageLbl);
        AddTextProperty(TaskPageSettings, CommunicationCulture, CommunicationDateFormatSourceLbl, CommunicationDateFormatLbl);
        AddTextProperty(TaskPageSettings, CommunicationCulture, CommunicationTimeFormatSourceLbl, CommunicationTimeFormatLbl);
        AddTextProperty(TaskPageSettings, CommunicationCulture, CommunicationFormattedNumberExampleSourceLbl, CommunicationFormattedNumberExampleLbl);
        exit(TaskPageSettings);
    end;

    local procedure AddContextToken(var ContextJson: JsonObject; ContextRoot: JsonObject; PropertyName: Text; ExpectArray: Boolean)
    var
        JsonToken: JsonToken;
    begin
        if not ContextRoot.Get(PropertyName, JsonToken) then
            exit;
        if ExpectArray and not JsonToken.IsArray() then
            exit;
        if not ExpectArray and not JsonToken.IsObject() then
            exit;

        ContextJson.Add(PropertyName, JsonToken);
    end;

    local procedure AddTextProperty(var TargetJson: JsonObject; SourceJson: JsonObject; SourcePropertyName: Text; TargetPropertyName: Text)
    begin
        if SourceJson.Contains(SourcePropertyName) then
            TargetJson.Add(TargetPropertyName, SourceJson.GetText(SourcePropertyName, true));
    end;

    local procedure BuildTaskContextJson(AgentTaskLogEntry: Record "Agent Task Log Entry"): JsonObject
    var
        AgentTask: Record "Agent Task";
        TaskContextJson: JsonObject;
    begin
        TaskContextJson.Add(TaskIdLbl, Format(AgentTaskLogEntry."Task ID", 0, 9));
        if not AgentTask.Get(AgentTaskLogEntry."Task ID") then
            exit(TaskContextJson);

        AgentTask.CalcFields("Agent Display Name");
        if AgentTask."Agent Display Name" <> '' then
            TaskContextJson.Add(AgentNameLbl, AgentTask."Agent Display Name");
        if AgentTask.Title <> '' then
            TaskContextJson.Add(TaskTitleLbl, AgentTask.Title);
        if AgentTask."Company Name" <> '' then
            TaskContextJson.Add(CompanyNameLbl, AgentTask."Company Name");
        exit(TaskContextJson);
    end;

    local procedure BuildMessagesJson(AgentTaskLogEntry: Record "Agent Task Log Entry"): JsonObject
    var
        MessagesJson: JsonObject;
        Messages: JsonArray;
    begin
        Messages := BuildMessageArray(AgentTaskLogEntry, true, false);
        if Messages.Count() > 0 then
            MessagesJson.Add(InputLbl, Messages);

        Clear(Messages);
        Messages := BuildMessageArray(AgentTaskLogEntry, false, false);
        if Messages.Count() > 0 then
            MessagesJson.Add(OutputLbl, Messages);

        Clear(Messages);
        Messages := BuildMessageArray(AgentTaskLogEntry, false, true);
        if Messages.Count() > 0 then
            MessagesJson.Add(EarlierLbl, Messages);

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

    var
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
        SerializedPageRedactedLbl: Label 'serializedPageRedacted', Locked = true;
        SerializedPageRedactionReasonLbl: Label 'serializedPageRedactionReason', Locked = true;
        PageStackLbl: Label 'pageStack', Locked = true;
        OrderLbl: Label 'order', Locked = true;
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
        AvailableToolsLbl: Label 'availableTools', Locked = true;
        MemorizedDataLbl: Label 'memorizedData', Locked = true;
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
}
