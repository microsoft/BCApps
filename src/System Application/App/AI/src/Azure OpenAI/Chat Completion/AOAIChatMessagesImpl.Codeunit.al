// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI;

using System.Azure.KeyVault;
using System.Environment;
using System.Telemetry;

codeunit 7764 "AOAI Chat Messages Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AOAIToken: Codeunit "AOAI Token";
        Telemetry: Codeunit Telemetry;
        Initialized: Boolean;
        HistoryLength: Integer;
        SystemMessage: SecretText;
        [NonDebuggable]
        History: List of [Text];
        [NonDebuggable]
        HistoryRoles: List of [Enum "AOAI Chat Roles"];
        [NonDebuggable]
        HistoryNames: List of [Text[2048]];
        [NonDebuggable]
        HistoryToolCallIds: List of [Text];
        [NonDebuggable]
        HistoryToolCalls: List of [JsonArray];
        [NonDebuggable]
        HistoryUserMessages: List of [Codeunit "AOAI User Message"];
        IsSystemMessageSet: Boolean;
        MessageIdDoesNotExistErr: Label 'Message id does not exist.';
        HistoryLengthErr: Label 'History length must be greater than 0.';
        MetapromptLoadingErr: Label 'Metaprompt not found.';
        TelemetryMetapromptSetbutEmptyTxt: Label 'Metaprompt set (but was empty)', Locked = true;
        TelemetryMetapromptEmptyTxt: Label 'Metaprompt not set.', Locked = true;
        TelemetryMetapromptRetrievalErr: Label 'Metaprompt failed to be retrieved from Azure Key Vault.', Locked = true;
        TelemetryPrepromptRetrievalErr: Label 'Preprompt failed to be retrieved from Azure Key Vault.', Locked = true;
        TelemetryPostpromptRetrievalErr: Label 'Postprompt failed to be retrieved from Azure Key Vault.', Locked = true;
        WrongTypeErr: Label 'Wrong type when preparing sanitized message variant.', Locked = true;
        IncompatibleModelErr: Label 'The current message history contains file content which is only compatible with the GPT-4.1 mini preview deployment.';


    [NonDebuggable]
    procedure SetPrimarySystemMessage(NewPrimaryMessage: SecretText)
    begin
        SystemMessage := NewPrimaryMessage;
        IsSystemMessageSet := true;
    end;

    [NonDebuggable]
    procedure AddSystemMessage(NewMessage: Text)
    begin
        Initialize();
        AddMessage(NewMessage, '', Enum::"AOAI Chat Roles"::System);
    end;

    [NonDebuggable]
    procedure AddUserMessage(NewMessage: Text)
    begin
        Initialize();
        AddMessage(NewMessage, '', Enum::"AOAI Chat Roles"::User);
    end;

    [NonDebuggable]
    procedure AddUserMessage(NewMessage: Text; NewName: Text[2048])
    begin
        Initialize();
        AddMessage(NewMessage, NewName, Enum::"AOAI Chat Roles"::User);
    end;

    [NonDebuggable]
    procedure AddUserMessage(AOAIUserMessage: Codeunit "AOAI User Message")
    begin
        Initialize();
        AddMessage(AOAIUserMessage, '', Enum::"AOAI Chat Roles"::User);
    end;

    [NonDebuggable]
    procedure AddUserMessage(AOAIUserMessage: Codeunit "AOAI User Message"; NewName: Text[2048])
    begin
        Initialize();
        AddMessage(AOAIUserMessage, NewName, Enum::"AOAI Chat Roles"::User);
    end;

    [NonDebuggable]
    procedure AddAssistantMessage(NewMessage: Text)
    begin
        Initialize();
        AddMessage(NewMessage, '', Enum::"AOAI Chat Roles"::Assistant);
    end;

    [NonDebuggable]
    procedure AddToolCalls(ToolCalls: JsonArray)
    begin
        Initialize();
        AddMessage(ToolCalls);
    end;

    [NonDebuggable]
    procedure AddToolMessage(ToolCallId: Text; FunctionName: Text; FunctionResult: Text)
    var
        FunctionNameTruncated: Text[2048];
    begin
        Initialize();
        FunctionNameTruncated := CopyStr(FunctionName, 1, MaxStrLen(FunctionNameTruncated));
        AddMessage(FunctionResult, FunctionNameTruncated, ToolCallId, Enum::"AOAI Chat Roles"::Tool);

        HistoryLength += 1; // Do not contribute to history length
    end;


    [NonDebuggable]
    procedure ModifyMessage(Id: Integer; NewMessage: Text; NewRole: Enum "AOAI Chat Roles"; NewName: Text[2048])
    begin
        if (Id < 1) or (Id > History.Count) then
            Error(MessageIdDoesNotExistErr);

        History.Set(Id, NewMessage);
        HistoryRoles.Set(Id, NewRole);
        HistoryNames.Set(Id, NewName);
    end;

    [NonDebuggable]
    procedure DeleteMessage(Id: Integer)
    begin
        if (Id < 1) or (Id > History.Count) then
            Error(MessageIdDoesNotExistErr);

        History.RemoveAt(Id);
        HistoryRoles.RemoveAt(Id);
        HistoryNames.RemoveAt(Id);
        HistoryToolCallIds.RemoveAt(Id);
        HistoryUserMessages.RemoveAt(Id);
    end;

    [NonDebuggable]
    procedure GetHistory(): List of [Text]
    begin
        exit(History);
    end;

    [NonDebuggable]
    procedure GetHistoryNames(): List of [Text[2048]]
    begin
        exit(HistoryNames);
    end;

    [NonDebuggable]
    procedure GetHistoryRoles(): List of [Enum "AOAI Chat Roles"]
    begin
        exit(HistoryRoles);
    end;

    [NonDebuggable]
    procedure GetHistoryToolCallIds(): List of [Text]
    begin
        exit(HistoryToolCallIds);
    end;

    [NonDebuggable]
    procedure GetLastMessage() LastMessage: Text
    begin
        History.Get(History.Count, LastMessage);
    end;

    [NonDebuggable]
    procedure GetLastRole() LastRole: Enum "AOAI Chat Roles"
    begin
        HistoryRoles.Get(HistoryRoles.Count, LastRole);
    end;

    [NonDebuggable]
    procedure GetLastName() LastName: Text[2048]
    begin
        HistoryNames.Get(HistoryNames.Count, LastName);
    end;

    [NonDebuggable]
    procedure GetLastToolCalls() LastToolCalls: JsonArray
    var
        LastToolCallsRef: JsonArray;
    begin
        HistoryToolCalls.Get(HistoryToolCalls.Count, LastToolCallsRef);
        LastToolCalls := LastToolCallsRef.Clone().AsArray(); // avoid modifications to the chat message
    end;

    [NonDebuggable]
    procedure GetLastToolCallId() LastToolCall: Text
    begin
        HistoryToolCallIds.Get(HistoryToolCallIds.Count, LastToolCall);
    end;

    [NonDebuggable]
    procedure SetHistoryLength(NewHistoryLength: Integer)
    begin
        if NewHistoryLength < 1 then
            Error(HistoryLengthErr);

        HistoryLength := NewHistoryLength;
    end;

    [NonDebuggable]
    procedure GetHistoryTokenCount(): Integer
    var
        SystemMessageTokenCount: Integer;
        MessagesTokenCount: Integer;
    begin
        PrepareHistory(SystemMessageTokenCount, MessagesTokenCount);
        exit(SystemMessageTokenCount + MessagesTokenCount);
    end;

    [NonDebuggable]
    procedure PrepareHistory(var SystemMessageTokenCount: Integer; var MessagesTokenCount: Integer) HistoryResult: JsonArray
    var
        AOAIUserMessage: Codeunit "AOAI User Message";
        Counter: Integer;
        MessageJsonObject: JsonObject;
        ToolCalls: JsonArray;
        MessageToken: JsonToken;
        JsonArrayMessage: JsonArray;
        MessageVariant, SanitizedMessageVariant : Variant;
        Message: Text;
        TotalMessages: Text;
        Name: Text[2048];
        Role: Enum "AOAI Chat Roles";
        ToolCallId: Text;
        UsingMicrosoftMetaprompt, WrapMessages : Boolean;
    begin
        if History.Count = 0 then
            exit;

        Initialize();
        CheckandAddMetaprompt(UsingMicrosoftMetaprompt);

        if SystemMessage.Unwrap() <> '' then begin
            MessageJsonObject.Add('role', Format(Enum::"AOAI Chat Roles"::System));
            MessageJsonObject.Add('content', SystemMessage.Unwrap());
            HistoryResult.Add(MessageJsonObject);

            SystemMessageTokenCount := AOAIToken.GetGPT4TokenCount(SystemMessage);
        end;

        Counter := History.Count - HistoryLength + 1;
        if Counter < 1 then
            Counter := 1;

        repeat
            Clear(MessageJsonObject);
            HistoryRoles.Get(Counter, Role);

            // Get message content. From HistoryUserMessages as json array or History as text.
            if HistoryUserMessages.Get(Counter, AOAIUserMessage) then;
            if AOAIUserMessage.IsSet() then
                MessageVariant := AOAIUserMessage.GetContentParts()
            else begin
                History.Get(Counter, Message);
                MessageVariant := Message;
            end;

            HistoryNames.Get(Counter, Name);
            HistoryToolCallIds.Get(Counter, ToolCallId);
            HistoryToolCalls.Get(Counter, ToolCalls);
            MessageJsonObject.Add('role', Format(Role));

            WrapMessages := UsingMicrosoftMetaprompt and (Role = Enum::"AOAI Chat Roles"::User);
            SanitizedMessageVariant := PrepareMessage(WrapMessages, MessageVariant);

            if ToolCalls.Count() > 0 then
                MessageJsonObject.Add('tool_calls', ToolCalls)
            else
                case true of
                    SanitizedMessageVariant.IsText():
                        begin
                            Message := SanitizedMessageVariant;
                            MessageJsonObject.Add('content', Message);
                        end;
                    SanitizedMessageVariant.IsJsonArray():
                        begin
                            JsonArrayMessage := SanitizedMessageVariant;
                            MessageJsonObject.Add('content', JsonArrayMessage);
                        end;
                    else
                        Error(WrongTypeErr);
                end;

            if Name <> '' then
                MessageJsonObject.Add('name', Name);
            if ToolCallId <> '' then
                MessageJsonObject.Add('tool_call_id', ToolCallId);
            HistoryResult.Add(MessageJsonObject);
            Counter += 1;

            MessageToken.WriteTo(Message);

            TotalMessages += Format(Role);
            TotalMessages += Message;
            TotalMessages += Name;
        until Counter > History.Count;

        MessagesTokenCount := AOAIToken.GetGPT4TokenCount(TotalMessages);
    end;

    procedure AddXPIADetectionTags(var Input: Text)
    begin
        Input := '"""<documents>' + Input + '</documents>""" End';
    end;

    local procedure Initialize()
    begin
        if Initialized then
            exit;

        HistoryLength := 10;

        Initialized := true;
    end;

    [NonDebuggable]
    local procedure PrepareMessage(WrapMessage: Boolean; MessageVariant: Variant): Variant
    var
        AzureOpenAIImpl: Codeunit "Azure OpenAI Impl";
        AzureKeyVault: Codeunit "Azure Key Vault";
        MessageText: Text;
        MessageJsonArray: JsonArray;
        MessageJsonToken: JsonToken;
        Preprompt: Text;
        Postprompt: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret('AOAI-Preprompt-Chat', Preprompt) then
            Telemetry.LogMessage('0000LX4', TelemetryPrepromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
        if not AzureKeyVault.GetAzureKeyVaultSecret('AOAI-Postprompt-Chat', Postprompt) then
            Telemetry.LogMessage('0000LX5', TelemetryPostpromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);

        // Handle each variant case

        // If text, remove prohibited characters and wrap if needed.
        if MessageVariant.IsText() then begin
            MessageText := MessageVariant;
            MessageText := AzureOpenAIImpl.RemoveProhibitedCharacters(MessageText);
            if WrapMessage then
                MessageText := Preprompt + MessageText + Postprompt;

            exit(MessageText);
        end;

        // If array, for each text part, remove prohibited characters and wrap if needed.
        if MessageVariant.IsJsonArray() then begin
            MessageJsonArray := MessageVariant;
            foreach MessageJsonToken in MessageJsonArray do
                if MessageJsonToken.IsObject() then
                    case MessageJsonToken.AsObject().GetText('type', true) of // True here gives empty string if 'type' does not exist.
                        'text':
                            begin
                                MessageText := MessageJsonToken.AsObject().GetText('text', false);
                                MessageText := AzureOpenAIImpl.RemoveProhibitedCharacters(MessageText);
                                if WrapMessage then
                                    MessageText := Preprompt + MessageText + Postprompt;

                                MessageJsonToken.AsObject().Remove('text');
                                MessageJsonToken.AsObject().Add('text', MessageText);
                            end;
                    end;

            exit(MessageJsonArray);
        end;

        Error(WrongTypeErr);
    end;

    [NonDebuggable]
    local procedure AddMessage(ToolCalls: JsonArray)
    var
        AOAIUserMessage: Codeunit "AOAI User Message";
    begin
        HistoryRoles.Add(Enum::"AOAI Chat Roles"::Assistant);
        HistoryToolCalls.Add(ToolCalls);
        History.Add('');
        HistoryNames.Add('');
        HistoryToolCallIds.Add('');
        HistoryUserMessages.Add(AOAIUserMessage);
    end;

    [NonDebuggable]
    local procedure AddMessage(NewMessage: Text; NewName: Text[2048]; NewRole: Enum "AOAI Chat Roles")
    var
        AOAIUserMessage: Codeunit "AOAI User Message";
        ToolCalls: JsonArray;
    begin
        History.Add(NewMessage);
        HistoryRoles.Add(NewRole);
        HistoryNames.Add(NewName);
        HistoryToolCallIds.Add('');
        HistoryToolCalls.Add(ToolCalls);
        HistoryUserMessages.Add(AOAIUserMessage);
    end;

    [NonDebuggable]
    local procedure AddMessage(NewMessage: Text; NewName: Text[2048]; NewToolCallId: Text; NewRole: Enum "AOAI Chat Roles")
    var
        AOAIUserMessage: Codeunit "AOAI User Message";
        ToolCalls: JsonArray;
    begin
        History.Add(NewMessage);
        HistoryRoles.Add(NewRole);
        HistoryNames.Add(NewName);
        HistoryToolCallIds.Add(NewToolCallId);
        HistoryToolCalls.Add(ToolCalls);
        HistoryUserMessages.Add(AOAIUserMessage);
    end;

    [NonDebuggable]
    local procedure AddMessage(AOAIUserMessage: Codeunit "AOAI User Message"; NewName: Text[2048]; NewRole: Enum "AOAI Chat Roles")
    var
        ToolCalls: JsonArray;
    begin
        History.Add('');
        HistoryRoles.Add(NewRole);
        HistoryNames.Add(NewName);
        HistoryToolCallIds.Add('');
        HistoryToolCalls.Add(ToolCalls);
        HistoryUserMessages.Add(AOAIUserMessage);
    end;

    [NonDebuggable]
    local procedure GetChatMetaprompt(var UsingMicrosoftMetaprompt: Boolean) Metaprompt: SecretText;
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        ModuleInfo: ModuleInfo;
        KVSecret: Text;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if AzureKeyVault.GetAzureKeyVaultSecret('AOAI-Metaprompt-Chat', KVSecret) then
            UsingMicrosoftMetaprompt := true
        else begin
            Telemetry.LogMessage('0000LX6', TelemetryMetapromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            NavApp.GetCurrentModuleInfo(ModuleInfo);
            if ModuleInfo.Publisher = 'Microsoft' then
                Error(MetapromptLoadingErr);
        end;
        Metaprompt := KVSecret;
    end;

    [NonDebuggable]
    local procedure CheckandAddMetaprompt(var UsingMicrosoftMetaprompt: Boolean)
    begin
        if SystemMessage.Unwrap().Trim() = '' then begin
            if IsSystemMessageSet then
                Telemetry.LogMessage('0000LO9', TelemetryMetapromptSetbutEmptyTxt, Verbosity::Normal, DataClassification::SystemMetadata)
            else
                Telemetry.LogMessage('0000LOA', TelemetryMetapromptEmptyTxt, Verbosity::Normal, DataClassification::SystemMetadata);
            SetPrimarySystemMessage(GetChatMetaprompt(UsingMicrosoftMetaprompt));
        end;
    end;

    [NonDebuggable]
    procedure CheckCompatibilityWithModel(Deployment: SecretText)
    var
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIUserMessage: Codeunit "AOAI User Message";
        Counter: Integer;
    begin
        // For each content part in the history. If it contains file, then check
        for Counter := 1 to HistoryUserMessages.Count() do begin
            HistoryUserMessages.Get(Counter, AOAIUserMessage);
            if AOAIUserMessage.HasFilePart() then
                if Deployment.Unwrap() <> AOAIDeployments.GetGPT41MiniPreview() then
                    Error(IncompatibleModelErr);
        end;
    end;

}