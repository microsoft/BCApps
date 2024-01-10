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
        IsSystemMessageSet: Boolean;
        MessageIdDoesNotExistErr: Label 'Message id does not exist.';
        HistoryLengthErr: Label 'History length must be greater than 0.';
        MetapromptLoadingErr: Label 'Metaprompt not found.';
        TelemetryMetapromptSetbutEmptyTxt: Label 'Metaprompt was set but is empty.', Locked = true;
        TelemetryMetapromptEmptyTxt: Label 'Metaprompt was not set.', Locked = true;
        TelemetryMetapromptRetrievalErr: Label 'Unable to retrieve metaprompt from Azure Key Vault.', Locked = true;
        TelemetryPrepromptRetrievalErr: Label 'Unable to retrieve preprompt from Azure Key Vault.', Locked = true;
        TelemetryPostpromptRetrievalErr: Label 'Unable to retrieve postprompt from Azure Key Vault.', Locked = true;

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
    procedure AddAssistantMessage(NewMessage: Text)
    begin
        Initialize();
        AddMessage(NewMessage, '', Enum::"AOAI Chat Roles"::Assistant);
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
    procedure SetHistoryLength(NewHistoryLength: Integer)
    begin
        if NewHistoryLength < 1 then
            Error(HistoryLengthErr);

        HistoryLength := NewHistoryLength;
    end;

    [NonDebuggable]
    procedure PrepareHistory(var SystemMessageTokenCount: Integer; var MessagesTokenCount: Integer) HistoryResult: JsonArray
    var
        AzureOpenAIImpl: Codeunit "Azure OpenAI Impl";
        Counter: Integer;
        MessageJsonObject: JsonObject;
        Message: Text;
        TotalMessages: Text;
        Name: Text[2048];
        Role: Enum "AOAI Chat Roles";
        UsingMicrosoftMetaprompt: Boolean;
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
            History.Get(Counter, Message);
            HistoryNames.Get(Counter, Name);
            MessageJsonObject.Add('role', Format(Role));
            if UsingMicrosoftMetaprompt and (Role = Enum::"AOAI Chat Roles"::User) then
                Message := WrapUserMessages(AzureOpenAIImpl.RemoveProhibitedCharacters(Message))
            else
                Message := AzureOpenAIImpl.RemoveProhibitedCharacters(Message);
            MessageJsonObject.Add('content', Message);

            if Name <> '' then
                MessageJsonObject.Add('name', Name);
            HistoryResult.Add(MessageJsonObject);
            Counter += 1;
            TotalMessages += Format(Role);
            TotalMessages += Message;
            TotalMessages += Name;
        until Counter > History.Count;

        MessagesTokenCount := AOAIToken.GetGPT4TokenCount(TotalMessages);
    end;

    local procedure Initialize()
    begin
        if Initialized then
            exit;

        HistoryLength := 10;

        Initialized := true;
    end;

    [NonDebuggable]
    local procedure AddMessage(NewMessage: Text; NewName: Text[2048]; NewRole: Enum "AOAI Chat Roles")
    begin
        History.Add(NewMessage);
        HistoryRoles.Add(NewRole);
        HistoryNames.Add(NewName);
    end;

    [NonDebuggable]
    local procedure WrapUserMessages(Message: Text): Text
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        Preprompt: Text;
        Postprompt: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret('AOAI-Preprompt-Chat', Preprompt) then begin
            Telemetry.LogMessage('0000LX4', TelemetryPrepromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            Error(MetapromptLoadingErr);
        end;
        if not AzureKeyVault.GetAzureKeyVaultSecret('AOAI-Postprompt-Chat', Postprompt) then begin
            Telemetry.LogMessage('0000LX5', TelemetryPostpromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            Error(MetapromptLoadingErr);
        end;

        exit(Preprompt + Message + Postprompt);
    end;

    [NonDebuggable]
    local procedure GetChatMetaprompt(var UsingMicrosoftMetaprompt: Boolean) Metaprompt: SecretText;
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        KVSecret: Text;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if AzureKeyVault.GetAzureKeyVaultSecret('AOAI-Metaprompt-Chat', KVSecret) then
            UsingMicrosoftMetaprompt := true
        else begin
            Telemetry.LogMessage('0000LX6', TelemetryMetapromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
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
}