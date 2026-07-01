// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using System;
using System.Azure.KeyVault;
using System.Telemetry;
using System.Utilities;

codeunit 4751 "Recommended Apps Impl."
{
    Access = Internal;

    var
        RecommendedApps: Record "Recommended Apps";
        AppSourceURLLbl: Label 'https://appsource.microsoft.com/%1/product/dynamics-365-business-central/PUBID.%2|AID.%3|PAPPID.%4?tab=Overview', Locked = true;
        URLNotWellFormattedErrLbl: Label 'Cannot add the recommended app with ID %1. The URL %2 is not formatted correctly. Are you sure that the information about the app is correct?',
            Comment = '%1 = App Id; %2 = App Source URL created with app info provided by the partner';
        CatalogApiUrlNotReachableErrLbl: Label 'Cannot add the recommended app with ID %1. The Marketplace Catalog API cannot be reached, and the HTTP status code is %2. Are you sure that the information about the app is correct?',
            Comment = '%1 = App Id; %2 = Http StatusCode';
        CatalogApiUrlLbl: Label 'https://catalogapi.azure.com/products/%1?market=US&api-version=2023-05-01-preview&language=en', Locked = true;
        AppSourceURLNotFoundErrLbl: Label 'Cannot get the AppSource URL.';
        CatalogApiKeyVaultSecretNameLbl: Label 'MarketplaceCatalogApi-Key', Locked = true;
        CannotGetApiKeyFromKeyVaultErrLbl: Label 'Cannot retrieve the Marketplace Catalog API key from Azure Key Vault.', Locked = true;

    [NonDebuggable]
    procedure InsertApp(Id: Guid; SortingId: Integer; Name: Text[250]; Publisher: Text[250]; ShortDescription: Text[250]; LongDescription: Text[2048];
    RecommendedBy: Enum "App Recommended By"; AppSourceURL: Text): Boolean
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        MemoryStream: DotNet MemoryStream;
        LanguageCode: Text[5];
        PubId: Text[100];
        AId: Text[100];
        PAppId: Text[100];
    begin
        // read the app information from the URL
        GetAppURLParametersFromAppSourceURL(Id, AppSourceURL, LanguageCode, PubId, AId, PAppId);

        CheckIfURLExistsAndDownloadLogo(Id, LanguageCode, PubId, AId, PAppId, MemoryStream);

        RecommendedApps.Init();
        RecommendedApps.Id := Id;
        RecommendedApps.SortingId := SortingId;
        RecommendedApps.Name := Name;
        RecommendedApps.Publisher := Publisher;
        RecommendedApps."Short Description" := ShortDescription;
        RecommendedApps."Long Description" := LongDescription;
        RecommendedApps.Logo.ImportStream(MemoryStream, 'logo', 'image/png');
        RecommendedApps."Recommended By" := RecommendedBy;
        RecommendedApps."Language Code" := LanguageCode;
        RecommendedApps.PubId := PubId;
        RecommendedApps.AId := AId;
        RecommendedApps.PAppId := PAppId;

        FeatureTelemetry.LogUsage('0000H7R', 'Recommended Apps', 'Recommended apps inserted');

        exit(RecommendedApps.Insert());
    end;

    [NonDebuggable]
    procedure GetApp(Id: Guid; var SortingId: Integer; var Name: Text[250]; var Publisher: Text[250]; var ShortDescription: Text[250]; var LongDescription: Text[2048];
        var RecommendedBy: Enum "App Recommended By"; var AppSourceURL: Text): Boolean
    begin
        if not RecommendedApps.Get(Id) then
            exit(false);

        SortingId := RecommendedApps.SortingId;
        Name := RecommendedApps.Name;
        Publisher := RecommendedApps.Publisher;
        ShortDescription := RecommendedApps."Short Description";
        LongDescription := RecommendedApps."Long Description";
        RecommendedBy := RecommendedApps."Recommended By";
        AppSourceURL := StrSubstNo(AppSourceURLLbl, RecommendedApps."Language Code", RecommendedApps.PubId, RecommendedApps.AId, RecommendedApps.PAppId);

        exit(true);
    end;

    [NonDebuggable]
    procedure UpdateApp(Id: Guid; SortingId: Integer; Name: Text[250]; Publisher: Text[250]; ShortDescription: Text[250]; LongDescription: Text[2048];
        RecommendedBy: Enum "App Recommended By"; AppSourceURL: Text): Boolean
    var
        MemoryStream: DotNet MemoryStream;
        LanguageCode: Text[5];
        PubId: Text[100];
        AId: Text[100];
        PAppId: Text[100];
        IsModified: Boolean;
    begin
        if not RecommendedApps.Get(Id) then
            exit(false);

        // read the app information from the URL
        GetAppURLParametersFromAppSourceURL(Id, AppSourceURL, LanguageCode, PubId, AId, PAppId);

        if RecommendedApps.SortingId <> SortingId then begin
            RecommendedApps.SortingId := SortingId;
            IsModified := true;
        end;

        if (RecommendedApps.Name <> Name)
            or (RecommendedApps.Publisher <> Publisher)
            or (RecommendedApps."Short Description" <> ShortDescription)
            or (RecommendedApps."Long Description" <> LongDescription)
            or (RecommendedApps."Recommended By" <> RecommendedBy)
        then begin
            RecommendedApps.Name := Name;
            RecommendedApps.Publisher := Publisher;
            RecommendedApps."Short Description" := ShortDescription;
            RecommendedApps."Long Description" := LongDescription;
            RecommendedApps."Recommended By" := RecommendedBy;
            IsModified := true;
        end;

        if (RecommendedApps."Language Code" <> LanguageCode) or (RecommendedApps.PubId <> PubId) or (RecommendedApps.AId <> AId) or (RecommendedApps.PAppId <> PAppId) then begin
            CheckIfURLExistsAndDownloadLogo(Id, LanguageCode, PubId, AId, PAppId, MemoryStream);
            RecommendedApps.Logo.ImportStream(MemoryStream, 'logo', 'image/png');
            RecommendedApps."Language Code" := LanguageCode;
            RecommendedApps.PubId := PubId;
            RecommendedApps.AId := AId;
            RecommendedApps.PAppId := PAppId;

            IsModified := true;
        end;

        if IsModified then
            exit(RecommendedApps.Modify());
        exit(true);
    end;

    [NonDebuggable]
    procedure RefreshImage(Id: Guid): Boolean
    var
        MemoryStream: DotNet MemoryStream;
    begin
        if not RecommendedApps.Get(Id) then
            exit(false);

        CheckIfURLExistsAndDownloadLogo(Id, RecommendedApps."Language Code", RecommendedApps.PubId, RecommendedApps.AId, RecommendedApps.PAppId, MemoryStream);
        RecommendedApps.Logo.ImportStream(MemoryStream, 'logo', 'image/png');

        exit(RecommendedApps.Modify());
    end;

    [NonDebuggable]
    procedure DeleteApp(Id: Guid): Boolean
    begin
        if not RecommendedApps.Get(Id) then
            exit(false);

        exit(RecommendedApps.Delete());
    end;

    [NonDebuggable]
    procedure DeleteAllApps()
    begin
        RecommendedApps.DeleteAll();
    end;

    [NonDebuggable]
    procedure GetAppURL(Id: Guid): Text
    begin
        if not RecommendedApps.Get(Id) then
            Error(AppSourceURLNotFoundErrLbl);

        exit(StrSubstNo(AppSourceURLLbl, RecommendedApps."Language Code", RecommendedApps.PubId, RecommendedApps.AId, RecommendedApps.PAppId));
    end;

    [NonDebuggable]
    local procedure GetAppURLParametersFromAppSourceURL(Id: Guid; AppSourceURL: Text; var LanguageCode: Text[5]; var PubId: Text[100]; var AId: Text[100]; var PAppId: Text[100])
    var
        Matches: Record Matches;
        Regex: Codeunit Regex;
        ErrMsg: Text;
    begin
        Regex.Match(AppSourceURL, '(?i)(?<=appsource.microsoft.com\/)(.+)(?=\/product)', 1, Matches);
        LanguageCode := CopyStr(Matches.ReadValue(), 1, 5);

        Regex.Match(AppSourceURL, '(?i)(?<=PUBID.)(.+)(?=(%7CAID|\|AID))', 1, Matches);
        PubId := CopyStr(Matches.ReadValue(), 1, 100);

        Regex.Match(AppSourceURL, '(?i)(?<=AID.)(.+)(?=(%7CPAPPID|\|PAPPID))', 1, Matches);
        AId := CopyStr(Matches.ReadValue(), 1, 100);

        Regex.Match(AppSourceURL, '(?i)(?<=PAPPID.)(.+)(?=(\?tab=Overview))|(?<=PAPPID.)(.+)(?=($))', 1, Matches);
        PAppId := CopyStr(Matches.ReadValue(), 1, 100);

        if (LanguageCode = '') or (PubId = '') or (AId = '') or (PAppId = '') then begin
            ErrMsg := StrSubstNo(URLNotWellFormattedErrLbl, Id, AppSourceURL);
            Error(ErrMsg);
        end
    end;

    [NonDebuggable]
    local procedure CheckIfURLExistsAndDownloadLogo(Id: Guid; LanguageCode: Text; PubId: Text; AId: Text; PAppId: Text; var MemoryStream: DotNet MemoryStream)
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
        ErrMsg: Text;
        ApiKey: SecretText;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(CatalogApiKeyVaultSecretNameLbl, ApiKey) then
            Error(CannotGetApiKeyFromKeyVaultErrLbl);

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
            exit;
        end;

        ErrMsg := StrSubstNo(CatalogApiUrlNotReachableErrLbl, Id, StatusCode);
        Error(ErrMsg);
    end;
}
