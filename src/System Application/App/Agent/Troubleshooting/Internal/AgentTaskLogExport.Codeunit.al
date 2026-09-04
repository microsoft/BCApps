// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;
using System.Environment;
using System.Utilities;

codeunit 4313 "Agent Task Log Export"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ExportToJson(var SelectedAgentTaskLogEntry: Record "Agent Task Log Entry"; var ExportOutStream: OutStream)
    var
        SelectedAgentTaskMemoryEntry: Record "Agent Task Memory Entry";
        AgentTaskID: BigInteger;
    begin
        AgentTaskID := GetTaskID(SelectedAgentTaskLogEntry);
        SetReferencedMemoryEntryFilter(SelectedAgentTaskLogEntry, SelectedAgentTaskMemoryEntry, AgentTaskID);
        ExportToJson(SelectedAgentTaskLogEntry, SelectedAgentTaskMemoryEntry, AgentTaskID, ExportOutStream);
    end;

    procedure ExportToJson(var SelectedAgentTaskLogEntry: Record "Agent Task Log Entry"; var SelectedAgentTaskMemoryEntry: Record "Agent Task Memory Entry"; AgentTaskID: BigInteger; var ExportOutStream: OutStream)
    var
        ExportRoot: JsonObject;
        IncludeSerializedPage: Boolean;
        CurrentGlobalLanguage: Integer;
        ErrorText: Text;
    begin
        IncludeSerializedPage := GetIncludeSerializedPage();
        CurrentGlobalLanguage := GlobalLanguage();
        GlobalLanguage(1033); // ENU

        if not TryBuildExportJson(SelectedAgentTaskLogEntry, SelectedAgentTaskMemoryEntry, AgentTaskID, IncludeSerializedPage, ExportRoot) then begin
            ErrorText := GetLastErrorText();
            GlobalLanguage(CurrentGlobalLanguage);
            Error(ErrorText);
        end;

        GlobalLanguage(CurrentGlobalLanguage);
        ExportRoot.WriteTo(ExportOutStream);
    end;

    [TryFunction]
    local procedure TryBuildExportJson(var SelectedAgentTaskLogEntry: Record "Agent Task Log Entry"; var SelectedAgentTaskMemoryEntry: Record "Agent Task Memory Entry"; AgentTaskID: BigInteger; IncludeSerializedPage: Boolean; var ExportRoot: JsonObject)
    var
        LogEntries: JsonArray;
        MemoryEntries: JsonArray;
    begin
        SelectedAgentTaskLogEntry.SetCurrentKey("Task ID", ID);
        SelectedAgentTaskLogEntry.SetAutoCalcFields("User Full Name");
        SelectedAgentTaskLogEntry.Ascending(true);
        if SelectedAgentTaskLogEntry.FindSet() then
            repeat
                LogEntries.Add(BuildEntryJson(SelectedAgentTaskLogEntry, IncludeSerializedPage));
            until SelectedAgentTaskLogEntry.Next() = 0;

        SelectedAgentTaskMemoryEntry.SetCurrentKey("Task ID", ID);
        SelectedAgentTaskMemoryEntry.SetAutoCalcFields("User Full Name");
        SelectedAgentTaskMemoryEntry.Ascending(true);
        if SelectedAgentTaskMemoryEntry.FindSet() then
            repeat
                MemoryEntries.Add(BuildMemoryEntryJson(SelectedAgentTaskMemoryEntry, IncludeSerializedPage));
            until SelectedAgentTaskMemoryEntry.Next() = 0;

        ExportRoot.Add(TaskContextLbl, BuildTaskContextJson(AgentTaskID));
        ExportRoot.Add(LogEntriesLbl, LogEntries);
        ExportRoot.Add(MemoryEntriesLbl, MemoryEntries);
    end;

    procedure ExportTaskToJson(AgentTaskID: BigInteger; var ExportOutStream: OutStream)
    var
        AgentTaskLogEntry: Record "Agent Task Log Entry";
        AgentTaskMemoryEntry: Record "Agent Task Memory Entry";
    begin
        AgentTaskLogEntry.SetRange("Task ID", AgentTaskID);
        AgentTaskMemoryEntry.SetRange("Task ID", AgentTaskID);
        ExportToJson(AgentTaskLogEntry, AgentTaskMemoryEntry, AgentTaskID, ExportOutStream);
    end;

    procedure ExportToJsonFile(var SelectedAgentTaskLogEntry: Record "Agent Task Log Entry"; AgentName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ExportOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(ExportOutStream, GetDefaultEncoding());
        ExportToJson(SelectedAgentTaskLogEntry, ExportOutStream);
        DownloadExport(TempBlob, AgentName);
    end;

    procedure ExportTaskToJsonFile(AgentTaskID: BigInteger; AgentName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ExportOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(ExportOutStream, GetDefaultEncoding());
        ExportTaskToJson(AgentTaskID, ExportOutStream);
        DownloadExport(TempBlob, AgentName);
    end;

    local procedure BuildEntryJson(var AgentTaskLogEntryRecord: Record "Agent Task Log Entry"; IncludeSerializedPage: Boolean): JsonObject
    var
        AgentTaskMemoryEntry: Record "Agent Task Memory Entry";
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        EntryJson: JsonObject;
        MessagesJson: JsonObject;
        RelatedLogEntries: JsonArray;
        IsAgentAction: Boolean;
        Success: Boolean;
        MemoryDetailsTxt: Text;
        ContextTxt: Text;
    begin
        EntryJson.Add(IdLbl, AgentTaskLogEntryRecord.ID);
        EntryJson.Add(TaskIdLbl, Format(AgentTaskLogEntryRecord."Task ID", 0, 9));
        EntryJson.Add(MemoryEntryIdLbl, AgentTaskLogEntryRecord."Memory Entry ID");
        EntryJson.Add(TypeLbl, Format(AgentTaskLogEntryRecord.Type));
        EntryJson.Add(LevelLbl, Format(AgentTaskLogEntryRecord.Level));
        EntryJson.Add(TimestampLbl, Format(AgentTaskLogEntryRecord.SystemCreatedAt, 0, 9));
        EntryJson.Add(UserFullNameLbl, AgentTaskLogEntryRecord."User Full Name");
        EntryJson.Add(UserSecurityIdLbl, Format(AgentTaskLogEntryRecord."User Security ID", 0, 9));
        EntryJson.Add(PageCaptionLbl, AgentTaskLogEntryRecord."Page Caption");
        EntryJson.Add(DescriptionLbl, AgentTaskLogEntryRecord.Description);
        EntryJson.Add(ReasonLbl, AgentTaskLogEntryRecord.Reason);
        EntryJson.Add(DetailsLbl, AgentTaskImpl.GetDetailsForAgentTaskLogEntry(AgentTaskLogEntryRecord));
        IsAgentAction := AgentTaskLogEntry.IsAgentAction(AgentTaskLogEntryRecord);
        EntryJson.Add(AgentActionLbl, IsAgentAction);
        EntryJson.Add(AgentNameLbl, AgentTaskLogEntry.GetAgentName(AgentTaskLogEntryRecord));

        if AgentTaskMemoryEntry.Get(AgentTaskLogEntryRecord."Task ID", AgentTaskLogEntryRecord."Memory Entry ID") then begin
            MemoryDetailsTxt := ReadMemoryEntryDetails(AgentTaskMemoryEntry);
        end;

        if AgentTaskLogEntry.GetSuccess(MemoryDetailsTxt, Success) then
            EntryJson.Add(SuccessLbl, Success);

        ContextTxt := AgentTaskLogEntry.ReadContext(AgentTaskLogEntryRecord);
        if (ContextTxt = '') and (AgentTaskMemoryEntry."Task ID" <> 0) then
            ContextTxt := AgentTaskLogEntry.ReadContext(AgentTaskMemoryEntry);
        AddTroubleshootingContext(EntryJson, ContextTxt, IncludeSerializedPage);
        if IsAgentAction and not EntryJson.Contains(DecisionPointLbl) then
            EntryJson.Add(DecisionPointLbl, false);

        MessagesJson := BuildMessagesJson(AgentTaskLogEntryRecord);
        AddMessageCollections(EntryJson, MessagesJson);

        RelatedLogEntries := BuildRelatedLogEntriesJson(AgentTaskLogEntryRecord);
        if RelatedLogEntries.Count() > 0 then
            EntryJson.Add(RelatedLogEntriesLbl, RelatedLogEntries);

        exit(EntryJson);
    end;

    local procedure BuildMemoryEntryJson(var AgentTaskMemoryEntry: Record "Agent Task Memory Entry"; IncludeSerializedPage: Boolean): JsonObject
    var
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        StepJson: JsonObject;
        ContextJson: JsonObject;
        DetailsTxt: Text;
        ContextTxt: Text;
    begin
        StepJson.Add(TaskIdLbl, Format(AgentTaskMemoryEntry."Task ID", 0, 9));
        StepJson.Add(IdLbl, AgentTaskMemoryEntry.ID);
        StepJson.Add(TypeLbl, Format(AgentTaskMemoryEntry.Type));
        StepJson.Add(TimestampLbl, Format(AgentTaskMemoryEntry.SystemCreatedAt, 0, 9));
        StepJson.Add(UserSecurityIdLbl, Format(AgentTaskMemoryEntry."User Security ID", 0, 9));
        if AgentTaskMemoryEntry.Description <> '' then
            StepJson.Add(DescriptionLbl, AgentTaskMemoryEntry.Description);

        if AgentTaskMemoryEntry."User Full Name" <> '' then
            StepJson.Add(UserFullNameLbl, AgentTaskMemoryEntry."User Full Name");

        DetailsTxt := ReadMemoryEntryDetails(AgentTaskMemoryEntry);
        if DetailsTxt <> '' then
            StepJson.Add(DetailsLbl, DetailsTxt);

        ContextTxt := AgentTaskLogEntry.ReadContext(AgentTaskMemoryEntry);
        BuildContextJson(ContextTxt, IncludeSerializedPage, ContextJson);
        if ContextJson.Keys().Count() > 0 then
            StepJson.Add(ContextLbl, ContextJson);

        exit(StepJson);
    end;

    local procedure ReadMemoryEntryDetails(var AgentTaskMemoryEntry: Record "Agent Task Memory Entry") MemoryDetailsTxt: Text
    var
        ContentInStream: InStream;
    begin
        AgentTaskMemoryEntry.CalcFields(Details);
        AgentTaskMemoryEntry.Details.CreateInStream(ContentInStream, GetDefaultEncoding());
        ContentInStream.Read(MemoryDetailsTxt);
    end;

    procedure BuildContextJson(ContextTxt: Text; IncludeSerializedPage: Boolean; var ContextJson: JsonObject)
    var
        ContextRoot: JsonObject;
        SerializedPageToken: JsonToken;
        PageStack: JsonArray;
        TaskPageSettings: JsonObject;
        RawSerializedPageJson: Text;
    begin
        Clear(ContextJson);
        if (ContextTxt = '') or not ContextRoot.ReadFrom(ContextTxt) then
            exit;

        if ContextRoot.Contains(IsDecisionPointLbl) then
            ContextJson.Add(DecisionPointLbl, ContextRoot.GetBoolean(IsDecisionPointLbl, true));

        PageStack := BuildPageStackJson(ContextRoot);
        if PageStack.Count() > 0 then
            ContextJson.Add(PageStackLbl, PageStack);

        AddContextToken(ContextJson, ContextRoot, AvailableToolsLbl, true);
        AddContextToken(ContextJson, ContextRoot, MemorizedDataLbl, false);

        TaskPageSettings := BuildTaskPageSettingsJson(ContextRoot);
        if TaskPageSettings.Keys().Count() > 0 then
            ContextJson.Add(TaskAndPageSettingsLbl, TaskPageSettings);

        RawSerializedPageJson := ContextRoot.GetText(SerializedPageLbl, true);
        if RawSerializedPageJson = '' then
            exit;

        if not IncludeSerializedPage then begin
            ContextJson.Add(PageContentRedactedLbl, true);
            ContextJson.Add(PageContentRedactionReasonLbl, AgentTroubleshooterMissingPermissionTxt);
            exit;
        end;

        if SerializedPageToken.ReadFrom(RawSerializedPageJson) then
            ContextJson.Add(PageContentLbl, SerializedPageToken)
        else
            ContextJson.Add(PageContentLbl, RawSerializedPageJson);
    end;

    local procedure AddTroubleshootingContext(var EntryJson: JsonObject; ContextTxt: Text; IncludeSerializedPage: Boolean)
    var
        ContextJson: JsonObject;
    begin
        BuildContextJson(ContextTxt, IncludeSerializedPage, ContextJson);
        AddJsonProperty(EntryJson, ContextJson, DecisionPointLbl);
        AddJsonProperty(EntryJson, ContextJson, PageContentLbl);
        AddJsonProperty(EntryJson, ContextJson, PageContentRedactedLbl);
        AddJsonProperty(EntryJson, ContextJson, PageContentRedactionReasonLbl);
        AddJsonProperty(EntryJson, ContextJson, AvailableToolsLbl);
        AddJsonProperty(EntryJson, ContextJson, MemorizedDataLbl);
        AddJsonProperty(EntryJson, ContextJson, PageStackLbl);
        AddJsonProperty(EntryJson, ContextJson, TaskAndPageSettingsLbl);
    end;

    local procedure AddJsonProperty(var TargetJson: JsonObject; SourceJson: JsonObject; PropertyName: Text)
    var
        PropertyToken: JsonToken;
    begin
        if SourceJson.Get(PropertyName, PropertyToken) then
            TargetJson.Add(PropertyName, PropertyToken);
    end;

    local procedure BuildPageStackJson(ContextRoot: JsonObject): JsonArray
    var
        PageStack: JsonArray;
        ExportPageStack: JsonArray;
        PageStackEntry: JsonObject;
        PageToken: JsonToken;
        Index: Integer;
        Order: Text;
    begin
        PageStack := ContextRoot.GetArray(PageStackLbl, true);
        Order := '1';
        for Index := 0 to PageStack.Count() - 1 do begin
            PageStack.Get(Index, PageToken);
            if PageToken.AsValue().IsNull() then
                continue;

            Clear(PageStackEntry);
            PageStackEntry.Add(OrderLbl, Order);
            PageStackEntry.Add(PageCaptionLbl, PageToken.AsValue().AsText());
            ExportPageStack.Add(PageStackEntry);
            Order := IncStr(Order);
        end;

        exit(ExportPageStack);
    end;

    local procedure BuildTaskPageSettingsJson(ContextRoot: JsonObject): JsonObject
    var
        TaskPageContext: JsonObject;
        CommunicationCulture: JsonObject;
        CommunicationJson: JsonObject;
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
        AddTextProperty(CommunicationJson, CommunicationCulture, CommunicationLanguageSourceLbl, CommunicationLanguageSourceLbl);
        AddTextProperty(CommunicationJson, CommunicationCulture, CommunicationDateFormatSourceLbl, CommunicationDateFormatSourceLbl);
        AddTextProperty(CommunicationJson, CommunicationCulture, CommunicationTimeFormatSourceLbl, CommunicationTimeFormatSourceLbl);
        AddTextProperty(CommunicationJson, CommunicationCulture, CommunicationFormattedNumberExampleSourceLbl, CommunicationFormattedNumberExampleSourceLbl);
        if CommunicationJson.Keys().Count() > 0 then
            TaskPageSettings.Add(CommunicationLbl, CreateCommunicationJson(CommunicationJson));
        exit(TaskPageSettings);
    end;

    local procedure CreateCommunicationJson(CultureJson: JsonObject): JsonObject
    var
        CommunicationJson: JsonObject;
    begin
        CommunicationJson.Add(CultureLbl, CultureJson);
        exit(CommunicationJson);
    end;

    local procedure AddContextToken(var ContextJson: JsonObject; ContextRoot: JsonObject; PropertyName: Text; ExpectArray: Boolean)
    var
        ContextPropertyToken: JsonToken;
    begin
        if not ContextRoot.Get(PropertyName, ContextPropertyToken) then
            exit;
        if ExpectArray and not ContextPropertyToken.IsArray() then
            exit;
        if not ExpectArray and not ContextPropertyToken.IsObject() then
            exit;

        ContextJson.Add(PropertyName, ContextPropertyToken);
    end;

    local procedure AddTextProperty(var TargetJson: JsonObject; SourceJson: JsonObject; SourcePropertyName: Text; TargetPropertyName: Text)
    begin
        if SourceJson.Contains(SourcePropertyName) then
            TargetJson.Add(TargetPropertyName, SourceJson.GetText(SourcePropertyName, true));
    end;

    local procedure BuildTaskContextJson(AgentTaskID: BigInteger): JsonObject
    var
        AgentTask: Record "Agent Task";
        TaskContextJson: JsonObject;
    begin
        TaskContextJson.Add(TaskIdLbl, Format(AgentTaskID, 0, 9));
        if not AgentTask.Get(AgentTaskID) then
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

    local procedure BuildMessagesJson(var AgentTaskLogEntry: Record "Agent Task Log Entry"): JsonObject
    var
        MessagesJson: JsonObject;
        Messages: JsonArray;
    begin
        case AgentTaskLogEntry.Type of
            AgentTaskLogEntry.Type::"Input Message":
                begin
                    Messages := BuildMessageArray(AgentTaskLogEntry, '=%1');
                    if Messages.Count() > 0 then
                        MessagesJson.Add(InputMessagesLbl, Messages);
                end;
            AgentTaskLogEntry.Type::"Output Message",
            AgentTaskLogEntry.Type::"Output Message Draft":
                begin
                    Messages := BuildMessageArray(AgentTaskLogEntry, '=%1');
                    if Messages.Count() > 0 then
                        MessagesJson.Add(OutputMessagesLbl, Messages);
                end;
        end;

        Clear(Messages);
        Messages := BuildMessageArray(AgentTaskLogEntry, '<%1');
        if Messages.Count() > 0 then
            MessagesJson.Add(EarlierMessagesLbl, Messages);

        exit(MessagesJson);
    end;

    local procedure AddMessageCollections(var EntryJson: JsonObject; MessagesJson: JsonObject)
    begin
        AddJsonProperty(EntryJson, MessagesJson, InputMessagesLbl);
        AddJsonProperty(EntryJson, MessagesJson, OutputMessagesLbl);
        AddJsonProperty(EntryJson, MessagesJson, EarlierMessagesLbl);
    end;

    local procedure BuildMessageArray(var AgentTaskLogEntry: Record "Agent Task Log Entry"; MemoryEntryFilter: Text): JsonArray
    var
        AgentTaskMessage: Record "Agent Task Message";
        Messages: JsonArray;
    begin
        AgentTaskMessage.SetRange("Task ID", AgentTaskLogEntry."Task ID");
        AgentTaskMessage.SetFilter("Memory Entry ID", MemoryEntryFilter, AgentTaskLogEntry."Memory Entry ID");

        AgentTaskMessage.SetCurrentKey("Memory Entry ID");
        AgentTaskMessage.Ascending(true);
        if AgentTaskMessage.FindSet() then
            repeat
                Messages.Add(BuildMessageJson(AgentTaskMessage));
            until AgentTaskMessage.Next() = 0;

        exit(Messages);
    end;

    local procedure BuildMessageJson(var AgentTaskMessage: Record "Agent Task Message"): JsonObject
    var
        AgentMessage: Codeunit "Agent Message";
        MessageJson: JsonObject;
    begin
        MessageJson.Add(IdLbl, Format(AgentTaskMessage.ID, 0, 9));
        MessageJson.Add(MemoryEntryIdLbl, AgentTaskMessage."Memory Entry ID");
        MessageJson.Add(TypeLbl, Format(AgentTaskMessage.Type));
        MessageJson.Add(StatusLbl, Format(AgentTaskMessage.Status));
        MessageJson.Add(CreatedAtLbl, Format(AgentTaskMessage.SystemCreatedAt, 0, 9));
        MessageJson.Add(ModifiedAtLbl, Format(AgentTaskMessage.SystemModifiedAt, 0, 9));
        MessageJson.Add(CreatedByFullNameLbl, AgentTaskMessage."Created By Full Name");
        MessageJson.Add(MessageLbl, AgentMessage.GetText(AgentTaskMessage));
        exit(MessageJson);
    end;

    local procedure BuildRelatedLogEntriesJson(var AgentTaskLogEntry: Record "Agent Task Log Entry"): JsonArray
    var
        SiblingLogEntry: Record "Agent Task Log Entry";
        RelatedLogEntries: JsonArray;
    begin
        SiblingLogEntry.SetRange("Task ID", AgentTaskLogEntry."Task ID");
        SiblingLogEntry.SetRange("Memory Entry ID", AgentTaskLogEntry."Memory Entry ID");
        SiblingLogEntry.SetFilter(ID, '<>%1', AgentTaskLogEntry.ID);
        SiblingLogEntry.SetCurrentKey(ID);
        SiblingLogEntry.SetAutoCalcFields("User Full Name");
        SiblingLogEntry.Ascending(true);
        if SiblingLogEntry.FindSet() then
            repeat
                RelatedLogEntries.Add(BuildRelatedLogEntryJson(SiblingLogEntry));
            until SiblingLogEntry.Next() = 0;

        exit(RelatedLogEntries);
    end;

    local procedure BuildRelatedLogEntryJson(var SiblingLogEntry: Record "Agent Task Log Entry"): JsonObject
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        SiblingActionJson: JsonObject;
    begin
        SiblingActionJson.Add(IdLbl, SiblingLogEntry.ID);
        SiblingActionJson.Add(TypeLbl, Format(SiblingLogEntry.Type));
        SiblingActionJson.Add(LevelLbl, Format(SiblingLogEntry.Level));
        SiblingActionJson.Add(DescriptionLbl, SiblingLogEntry.Description);
        SiblingActionJson.Add(ReasonLbl, SiblingLogEntry.Reason);
        SiblingActionJson.Add(DetailsLbl, AgentTaskImpl.GetDetailsForAgentTaskLogEntry(SiblingLogEntry));
        SiblingActionJson.Add(PageCaptionLbl, SiblingLogEntry."Page Caption");
        SiblingActionJson.Add(UserFullNameLbl, SiblingLogEntry."User Full Name");
        SiblingActionJson.Add(TimestampLbl, Format(SiblingLogEntry.SystemCreatedAt, 0, 9));
        exit(SiblingActionJson);
    end;

    local procedure GetTaskID(var SelectedAgentTaskLogEntry: Record "Agent Task Log Entry"): BigInteger
    begin
        if SelectedAgentTaskLogEntry.FindFirst() then
            exit(SelectedAgentTaskLogEntry."Task ID");
    end;

    local procedure SetReferencedMemoryEntryFilter(var SelectedAgentTaskLogEntry: Record "Agent Task Log Entry"; var SelectedAgentTaskMemoryEntry: Record "Agent Task Memory Entry"; AgentTaskID: BigInteger)
    var
        MemoryEntryFilter: Text;
    begin
        SelectedAgentTaskMemoryEntry.SetRange("Task ID", AgentTaskID);
        if SelectedAgentTaskLogEntry.FindSet() then
            repeat
                if (SelectedAgentTaskLogEntry."Memory Entry ID" <> 0) and
                   (StrPos('|' + MemoryEntryFilter + '|', '|' + Format(SelectedAgentTaskLogEntry."Memory Entry ID", 0, 9) + '|') = 0)
                then
                    if MemoryEntryFilter = '' then
                        MemoryEntryFilter := Format(SelectedAgentTaskLogEntry."Memory Entry ID", 0, 9)
                    else
                        MemoryEntryFilter += '|' + Format(SelectedAgentTaskLogEntry."Memory Entry ID", 0, 9);
            until SelectedAgentTaskLogEntry.Next() = 0;

        if MemoryEntryFilter = '' then
            SelectedAgentTaskMemoryEntry.SetRange(ID, 0)
        else
            SelectedAgentTaskMemoryEntry.SetFilter(ID, MemoryEntryFilter);
    end;

    local procedure GetIncludeSerializedPage(): Boolean
    var
        FeatureAccessManagement: Codeunit "Feature Access Management";
        AgentSystemPermissionsImpl: Codeunit "Agent System Permissions Impl.";
    begin
        FeatureAccessManagement.AgentManagementAllowed(true);
        exit(AgentSystemPermissionsImpl.CurrentUserHasTroubleshootAllAgents());
    end;

    local procedure DownloadExport(var TempBlob: Codeunit "Temp Blob"; AgentName: Text)
    var
        ExportInStream: InStream;
        FileName: Text;
    begin
        TempBlob.CreateInStream(ExportInStream, GetDefaultEncoding());
        FileName := StrSubstNo(ExportFileNameLbl, RemoveNonAlphanumericCharacters(AgentName), Format(Today(), 0, 9));
        DownloadFromStream(ExportInStream, ExportDialogTitleLbl, '', JsonFileFilterLbl, FileName);
    end;

    local procedure RemoveNonAlphanumericCharacters(Value: Text) AlphanumericValue: Text
    begin
        AlphanumericValue := DelChr(Value, '=', DelChr(Value, '=', AllowedAlphanumericCharactersTok));
        exit(AlphanumericValue);
    end;

    local procedure GetDefaultEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    var
        AgentTroubleshooterMissingPermissionTxt: Label 'Only users who are assigned the ''Troubleshoot All Agents'' permission can view page snapshot data.';
        LogEntriesLbl: Label 'logEntries', Locked = true;
        MemoryEntriesLbl: Label 'memoryEntries', Locked = true;
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
        ContextLbl: Label 'context', Locked = true;
        TaskContextLbl: Label 'taskContext', Locked = true;
        PageContentLbl: Label 'pageContent', Locked = true;
        PageContentRedactedLbl: Label 'pageContentRedacted', Locked = true;
        PageContentRedactionReasonLbl: Label 'pageContentRedactionReason', Locked = true;
        PageStackLbl: Label 'pageStack', Locked = true;
        OrderLbl: Label 'order', Locked = true;
        TaskAndPageSettingsLbl: Label 'taskAndPageSettings', Locked = true;
        CurrencyCodeLbl: Label 'currencyCode', Locked = true;
        CurrencySymbolLbl: Label 'currencySymbol', Locked = true;
        OutgoingCommunicationCultureLbl: Label 'outgoingCommunicationCulture', Locked = true;
        CommunicationLbl: Label 'communication', Locked = true;
        CultureLbl: Label 'culture', Locked = true;
        CommunicationLanguageSourceLbl: Label 'language', Locked = true;
        CommunicationDateFormatSourceLbl: Label 'dateFormat', Locked = true;
        CommunicationTimeFormatSourceLbl: Label 'timeFormat', Locked = true;
        CommunicationFormattedNumberExampleSourceLbl: Label 'formattedNumberExample', Locked = true;
        AvailableToolsLbl: Label 'availableTools', Locked = true;
        MemorizedDataLbl: Label 'memorizedData', Locked = true;
        TaskTitleLbl: Label 'taskTitle', Locked = true;
        CompanyNameLbl: Label 'companyName', Locked = true;
        InputMessagesLbl: Label 'inputMessages', Locked = true;
        OutputMessagesLbl: Label 'outputMessages', Locked = true;
        EarlierMessagesLbl: Label 'earlierMessages', Locked = true;
        MessageLbl: Label 'message', Locked = true;
        StatusLbl: Label 'status', Locked = true;
        RelatedLogEntriesLbl: Label 'relatedLogEntries', Locked = true;
        SerializedPageLbl: Label 'serializedPage', Locked = true;
        IsDecisionPointLbl: Label 'isDecisionPoint', Locked = true;
        TaskPageContextLbl: Label 'taskPageContext', Locked = true;
        ExportFileNameLbl: Label 'AgentTaskLog_%1_%2.json', Comment = '%1 is the agent name and %2 is the export date.', Locked = true;
        ExportDialogTitleLbl: Label 'Export agent task log';
        JsonFileFilterLbl: Label 'JSON files (*.json)|*.json', Locked = true;
        AllowedAlphanumericCharactersTok: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789', Locked = true;
}
