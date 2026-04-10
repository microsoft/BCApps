// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using System.Environment;
using System.Integration;

codeunit 5456 "Graph Connection Setup"
{

    trigger OnRun()
    begin
    end;

    var
        PwdConnectionStringTxt: Label '{ENTITYLISTENDPOINT}=%1;{ENTITYENDPOINT}=%2', Locked = true;
        S2SConnectionStringTxt: Label '{ENTITYLISTENDPOINT}=%1;{ENTITYENDPOINT}=%2;{EXORESOURCEURI}=%3;{EXORESOURCEROLE}=%4;', Locked = true;
        GraphResourceUrlTxt: Label 'https://outlook.office365.com/', Locked = true;

    procedure CanRunSync(): Boolean
    var
        ForceSync: Boolean;
    begin
        OnCheckForceSync(ForceSync);
        if ForceSync then
            exit(true);

        if GetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph) <> '' then
            exit(false);

        exit(true);
    end;

    procedure ConstructConnectionString(EntityEndpoint: Text; EntityListEndpoint: Text; ResourceUri: Text; ResourceRoles: Text) ConnectionString: Text
    begin
        if IsS2SAuthenticationEnabled() then
            ConnectionString := S2SConnectionStringTxt
        else
            ConnectionString := PwdConnectionStringTxt;

        if ResourceUri = '' then
            ResourceUri := GraphResourceUrlTxt;

        ConnectionString := StrSubstNo(ConnectionString, EntityListEndpoint, EntityEndpoint, ResourceUri, ResourceRoles);
    end;

    procedure GetGraphNotificationUrl(): Text[250]
    var
        WebhookManagement: Codeunit "Webhook Management";
    begin
        exit(WebhookManagement.GetNotificationUrl());
    end;

    procedure GetInboundConnectionName(TableID: Integer) ConnectionName: Text
    begin
        OnGetInboundConnectionName(TableID, ConnectionName);
    end;

    procedure GetInboundConnectionString(TableID: Integer) ConnectionString: Text
    begin
        OnGetInboundConnectionString(TableID, ConnectionString);
    end;

    procedure GetSubscriptionConnectionName(TableID: Integer) ConnectionName: Text
    begin
        OnGetSubscriptionConnectionName(TableID, ConnectionName);
    end;

    procedure GetSubscriptionConnectionString(TableID: Integer) ConnectionString: Text
    begin
        OnGetSubscriptionConnectionString(TableID, ConnectionString);
    end;

    procedure GetSynchronizeConnectionName(TableID: Integer) ConnectionName: Text
    begin
        OnGetSynchronizeConnectionName(TableID, ConnectionName);
    end;

    procedure GetSynchronizeConnectionString(TableID: Integer) ConnectionString: Text
    begin
        OnGetSynchronizeConnectionString(TableID, ConnectionString);
    end;

    procedure RegisterConnectionForEntity(InboundConnectionName: Text; InboundConnectionString: Text; SubscriptionConnectionName: Text; SubscriptionConnectionString: Text; SynchronizeConnectionName: Text; SynchronizeConnectionString: Text)
    begin
        RegisterConnectionWithName(InboundConnectionName, InboundConnectionString);
        RegisterConnectionWithName(SubscriptionConnectionName, SubscriptionConnectionString);
        RegisterConnectionWithName(SynchronizeConnectionName, SynchronizeConnectionString);
    end;

    procedure RegisterConnections()
    begin
        OnRegisterConnections();
    end;

    [Scope('OnPrem')]
    procedure IsS2SAuthenticationEnabled(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
        IsHandled: Boolean;
        IsS2SAuthentication: Boolean;
    begin
        OnIsS2SAuthenticationEnabled(IsS2SAuthentication, IsHandled);
        if IsHandled then
            exit(IsS2SAuthentication);
        exit(EnvironmentInfo.IsProduction());
    end;

    local procedure RegisterConnectionWithName(ConnectionName: Text; ConnectionString: Text)
    begin
        if '' in [ConnectionName, ConnectionString] then
            exit;

        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, ConnectionString);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckForceSync(var Force: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetInboundConnectionName(TableID: Integer; var ConnectionName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetInboundConnectionString(TableID: Integer; var ConnectionString: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSubscriptionConnectionName(TableID: Integer; var ConnectionName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSubscriptionConnectionString(TableID: Integer; var ConnectionString: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSynchronizeConnectionName(TableID: Integer; var ConnectionName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSynchronizeConnectionString(TableID: Integer; var ConnectionString: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterConnections()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsS2SAuthenticationEnabled(var IsS2SAuthentication: Boolean; var IsHandled: Boolean);
    begin

    end;
}

