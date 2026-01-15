// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.eServices.EDocument.Integration;
using System.Azure.Identity;
using System.Environment;
codeunit 6424 "ForNAV Peppol Setup"
{
    SingleInstance = true;
    Access = Internal;
    Permissions = tabledata "ForNAV Peppol Setup" = RIM;
    EventSubscriberInstance = Manual;

    var
        AccessToken: SecretText;
        AccessTokenExpires: DateTime;
        InitCalled: Boolean;
        License: Text;
        LicenseObject: JsonObject;

    internal procedure NotificationLink(Notification: Notification)
    var
        Setup: Record "ForNAV Peppol Setup";
    begin
        Setup.InitSetup();
        Hyperlink((Setup.SetupNotificationUrl));
    end;

    [InternalEvent(false)]
    local procedure OnBeforeSend(var HttpClient: HttpClient; Http: Codeunit "Http Message State"; var Handled: Boolean)
    begin
    end;

    internal procedure Send(var HttpClient: HttpClient; Http: Codeunit "Http Message State") Result: integer
    var
        Handled: Boolean;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
    begin
        AddForNavHeaders(Http);
        OnBeforeSend(HttpClient, Http, Handled);
        if Handled then
            exit(Http.GetHttpResponseMessage().HttpStatusCode);

        HttpRequestMessage := Http.GetHttpRequestMessage();
        if not AddSecurityHeaders(HttpRequestMessage) then
            exit(401);
        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
        RemoveSecurityHeaders(HttpRequestMessage);
        Http.SetHttpResponseMessage(HttpResponseMessage);
        Http.SetHttpRequestMessage(HttpRequestMessage);
        exit(HttpResponseMessage.HttpStatusCode);
    end;

    [NonDebuggable]
    internal procedure GetBaseUrl(AzureMethodName: Text): Text
    var
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        exit(PeppolOauth.GetPeppolEndpointURL() + AzureMethodName);
    end;

    internal procedure GetJLicense(): JsonObject
    begin
        if License = '' then
            InitLicens();
        exit(LicenseObject);
    end;

    internal procedure GetLicense(): Text
    begin
        if License = '' then
            InitLicens();
        exit(License);
    end;

    internal procedure Init(var Setup: Record "ForNAV Peppol Setup")
    var
        SMP: Codeunit "ForNAV Peppol SMP";
    begin
        if InitCalled then begin
            if Setup.Status <> Setup.Status::Published then
                Setup.UpdateFromCompanyInformation();
        end else begin
            InitLicens();
            Setup.InitSetup();
            if Setup.Authorized then
                SMP.ParticipantExists(Setup);
            InitCalled := true;
        end;
    end;

    internal procedure Close()
    begin
        InitCalled := false;
    end;

    [NonDebuggable]
    local procedure AddForNavHeaders(Http: Codeunit "Http Message State")
    var
        PeppolSetup: Record "ForNAV Peppol Setup";
        HttpHeaders: HttpHeaders;
    begin
        Http.GetHttpRequestMessage().GetHeaders(HttpHeaders);
        HttpHeaders.Add('license', GetLicense());
        PeppolSetup.InitSetup();
        HttpHeaders.Add('peppolid', PeppolSetup.PeppolId());
        HttpHeaders.Add('identifier', PeppolSetup.ID());
        HttpHeaders.Add('istest', PeppolSetup.IsTest() ? 'true' : 'false');
        HttpHeaders.Add('lcid', Format(GlobalLanguage));
    end;

    local procedure AddSecurityHeaders(var HttpRequestMessage: HttpRequestMessage): Boolean
    var
        PeppolSetup: Record "ForNAV Peppol Setup";
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
        OAuthToken: Codeunit "ForNAV Peppol Oauth Token";
        HttpHeaders: HttpHeaders;
    begin
        RemoveSecurityHeaders(HttpRequestMessage);
        HttpRequestMessage.GetHeaders(HttpHeaders);
        PeppolSetup.InitSetup();

        if PeppolOauth.GetSecretValidTo() < CreateDateTime(CalcDate('<+2m>', Today), Time) then
            PeppolSetup.RotateClientSecret();

        if (AccessToken.IsEmpty()) or (AccessTokenExpires < CurrentDateTime) then begin
            if not OAuthToken.AcquireTokenWithClientCredentials(PeppolOauth.GetClientID(), PeppolOauth.GetClientSecret(), PeppolOauth.GetOAuthAuthorityUrl(), '', PeppolOauth.GetEndpointScope()) then
                exit(false);

            OAuthToken.GetAccessToken(AccessToken, AccessTokenExpires);
            PeppolOauth.StoreRoles(OAuthToken.GetRoles());
        end;

        if AccessToken.IsEmpty() then
            exit(false);

        exit(HttpHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', AccessToken)));
    end;

    local procedure RemoveSecurityHeaders(var HttpRequestMessage: HttpRequestMessage)
    var
        HttpHeaders: HttpHeaders;
    begin
        HttpRequestMessage.GetHeaders(HttpHeaders);
        if HttpHeaders.Contains('x-functions-key') then
            HttpHeaders.Remove('x-functions-key');
        if HttpHeaders.Contains('Authorization') then
            HttpHeaders.Remove('Authorization');
    end;

    internal procedure ClearAccessToken()
    begin
        Clear(AccessToken);
        Clear(AccessTokenExpires);
    end;

    local procedure InitLicens()
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        EnvironmentInformation: Codeunit "Environment Information";
        TenantInformation: Codeunit "Tenant Information";
        Plan: Query Plan;
        UsersInPlans: Query "Users in Plans";
        UserCount: Integer;
        PlansObject: JsonObject;
        AppModuleInfo: ModuleInfo;
    begin
        Clear(LicenseObject);
        Plan.Open();
        while Plan.Read() do begin
            UserCount := 0;
            UsersInPlans.SetRange(Plan_ID, Plan.Plan_ID);
            UsersInPlans.Open();
            while UsersInPlans.Read() do
                UserCount += 1;
            if (UserCount <> 0) and not PlansObject.Keys.Contains(Plan.Plan_Name) then
                PlansObject.Add(Plan.Plan_Name, UserCount);
        end;
        LicenseObject.Add('plans', PlansObject);
        if EnvironmentInformation.IsSaaSInfrastructure() then begin
            LicenseObject.Add('AadTenantDomainName', AzureADTenant.GetAadTenantDomainName());
            LicenseObject.Add('AadTenantId', AzureADTenant.GetAadTenantId());
            LicenseObject.Add('TenantId', TenantInformation.GetTenantId());
            LicenseObject.Add('TenantDisplayName', TenantInformation.GetTenantDisplayName());
            LicenseObject.Add('IsSandbox', EnvironmentInformation.IsSandbox());
            LicenseObject.Add('IsProduction', EnvironmentInformation.IsProduction());
            LicenseObject.Add('EnvironmentName', EnvironmentInformation.GetEnvironmentName());
        end else
            LicenseObject.Add('SerialNumber', Database.SerialNumber);
        NavApp.GetCurrentModuleInfo(AppModuleInfo);
        LicenseObject.Add('AppVersion', Format(AppModuleInfo.AppVersion));
        LicenseObject.Add('CurrAppVersion', Format(AppModuleInfo.AppVersion));

        LicenseObject.WriteTo(License);
    end;
}