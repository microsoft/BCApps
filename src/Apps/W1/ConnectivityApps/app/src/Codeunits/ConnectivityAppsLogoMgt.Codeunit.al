// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247

codeunit 20353 "Connectivity Apps Logo Mgt."
{
    Access = Internal;
    Permissions = tabledata "Connectivity App Logo" = RIMD;

    var
        CatalogApiUrlLbl: Label 'https://catalogapi.azure.com/products/%1?market=US&api-version=2023-05-01-preview&language=en', Locked = true;
        IncorrectAppSourceUrlLbl: Label '%1 is not a correct AppSource URL.', Locked = true, Comment = '%1 = App source URL';
        LogoDownloadFailedLbl: Label 'Logo download failed from Catalog API for PUBID.%1|AID.%2|PAPPID.%3', Locked = true, Comment = '%1 = Publisher ID, %2 = App ID, %3 = Plan App ID';
        TelemetryCategoryLbl: Label 'Connectivity Apps', Locked = true;
        CatalogApiKeyVaultSecretNameLbl: Label 'MarketplaceCatalogApi-Key', Locked = true;
        CannotGetApiKeyFromKeyVaultLbl: Label 'Cannot retrieve the Marketplace Catalog API key from Azure Key Vault.', Locked = true;

    procedure LoadImages(var ConnectivityApp: Record "Connectivity App")
    var
        ConnectivityAppLogo: Record "Connectivity App Logo";
        RefreshAppLogo: Boolean;
    begin
        if ConnectivityApp.FindSet() then begin
            repeat
                if ConnectivityAppLogo.Get(ConnectivityApp."App Id") then begin
                    if not RefreshAppLogo then
                        if ConnectivityAppLogo."Expiry Date" < CurrentDateTime then
                            RefreshAppLogo := true;
                    ConnectivityApp.Logo := ConnectivityAppLogo.Logo;
                    ConnectivityApp.Modify();
                end else
                    GetAppLogoFromAppSource(ConnectivityApp);
            until ConnectivityApp.Next() = 0;

            if RefreshAppLogo then
                ScheduleLogoRefresh();
        end;
    end;

    procedure RefreshLogoFromAppSource(var ConnectivityAppLogo: Record "Connectivity App Logo")
    var
        MemoryStream: DotNet MemoryStream;
        PubId: Text[100];
        AId: Text[100];
        PAppId: Text[100];
    begin
        if GetAppURLParametersFromAppSourceURL(ConnectivityAppLogo."AppSource URL", PubId, AId, PAppId) then
            if CheckIfURLExistsAndDownloadLogo(PubId, AId, PAppId, MemoryStream) then begin
                ConnectivityAppLogo.Logo.ImportStream(MemoryStream, 'logo', 'image/png');
                ConnectivityAppLogo."Expiry Date" := GetConnectivityAppLogoExpiryDate();
                ConnectivityAppLogo.Modify();
            end;
    end;

    local procedure ScheduleLogoRefresh()
    var
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
    begin
        JobQueueEntry.ScheduleJobQueueEntry(Codeunit::"Connectivity Apps Logo Refresh", BlankRecordId);
    end;

    local procedure GetAppLogoFromAppSource(var ConnectivityApp: Record "Connectivity App")
    var
        ConnectivityAppLogo: Record "Connectivity App Logo";
        MemoryStream: DotNet MemoryStream;
        PubId: Text[100];
        AId: Text[100];
        PAppId: Text[100];
    begin
        if GetAppURLParametersFromAppSourceURL(ConnectivityApp."AppSource URL", PubId, AId, PAppId) then
            if CheckIfURLExistsAndDownloadLogo(PubId, AId, PAppId, MemoryStream) then begin
                ConnectivityAppLogo."App Id" := ConnectivityApp."App Id";
                ConnectivityAppLogo.Logo.ImportStream(MemoryStream, 'logo', 'image/png');
                ConnectivityAppLogo."AppSource URL" := ConnectivityApp."AppSource URL";
                ConnectivityAppLogo."Expiry Date" := GetConnectivityAppLogoExpiryDate();
                ConnectivityAppLogo.Insert();

                ConnectivityApp.Logo := ConnectivityAppLogo.Logo;
                ConnectivityApp.Modify();
            end;
    end;

    local procedure GetAppURLParametersFromAppSourceURL(AppSourceURL: Text; var PubId: Text[100]; var AId: Text[100]; var PAppId: Text[100]): Boolean
    var
        Matches: Record Matches;
        Regex: Codeunit Regex;
    begin
        Regex.Match(AppSourceURL, '(?i)(?<=PUBID.)(.+)(?=(%7CAID|\|AID))', 1, Matches);
        PubId := CopyStr(Matches.ReadValue(), 1, 100);

        Regex.Match(AppSourceURL, '(?i)(?<=AID.)(.+)(?=(%7CPAPPID|\|PAPPID))', 1, Matches);
        AId := CopyStr(Matches.ReadValue(), 1, 100);

        Regex.Match(AppSourceURL, '(?i)(?<=PAPPID.)(.+)(?=(\?tab=Overview))|(?<=PAPPID.)(.+)(?=($))', 1, Matches);
        PAppId := CopyStr(Matches.ReadValue(), 1, 100);

        if (PubId <> '') and (AId <> '') and (PAppId <> '') then
            exit(true);

        Session.LogMessage('0000I4I', StrSubstNo(IncorrectAppSourceUrlLbl, AppSourceURL), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
        exit(false);
    end;

    local procedure CheckIfURLExistsAndDownloadLogo(PubId: Text; AId: Text; PAppId: Text; var MemoryStream: DotNet MemoryStream): Boolean
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        WebClient: DotNet WebClient;
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        JsonObj: JsonObject;
        JsonTok: JsonToken;
        StatusCode: Integer;
        HttpResponseBodyText: Text;
        LogoURL: Text;
        ApiKey: SecretText;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(CatalogApiKeyVaultSecretNameLbl, ApiKey) then begin
            Session.LogMessage('0000NEW', CannotGetApiKeyFromKeyVaultLbl, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
            exit(false);
        end;

        HttpClient.DefaultRequestHeaders().Add('X-API-Key', ApiKey);
        HttpClient.Get(StrSubstNo(CatalogApiUrlLbl, PubId), HttpResponseMessage);
        StatusCode := HttpResponseMessage.HttpStatusCode();

        if (StatusCode = 200) then begin
            HttpResponseMessage.Content().ReadAs(HttpResponseBodyText);
            JsonObj.ReadFrom(HttpResponseBodyText);
            JsonObj.Get('largeIconUri', JsonTok);
            LogoURL := JsonTok.AsValue().AsText();

            WebClient := WebClient.WebClient();
            MemoryStream := MemoryStream.MemoryStream(WebClient.DownloadData(LogoURL));
            exit(true);
        end;

        Session.LogMessage('0000I4J', StrSubstNo(LogoDownloadFailedLbl, PubId, AId, PAppId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
        exit(false);
    end;

    local procedure GetConnectivityAppLogoExpiryDate(): DateTime
    begin
        exit(CurrentDateTime() + 14400 * 1000); // Cache lives for 10 days
    end;
}
