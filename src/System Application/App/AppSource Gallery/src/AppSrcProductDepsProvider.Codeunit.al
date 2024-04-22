// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

using System.Environment.Configuration;
using System.Globalization;
using System.Azure.Identity;
using System.Environment;
using System.RestClient;

/// <summary>
/// Provides the dependencies used by the AppSource Gallery module.
/// </summary>
codeunit 2518 "AppSrc Product Deps. Provider" implements "AppSource Product Manager Dependencies"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetCountryLetterCode(): Code[2]
    var
        AzureAdTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureAdTenant.GetCountryLetterCode());
    end;

    procedure GetPreferredLanguage(): Text
    var
        AzureAdTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureAdTenant.GetPreferredLanguage());
    end;

    procedure GetApplicationFamily(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.GetApplicationFamily());
    end;

    procedure IsSaas(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSaas());
    end;

    procedure GetFormatRegionOrDefault(FormatRegion: Text[80]): Text
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetFormatRegionOrDefault(FormatRegion));
    end;

    procedure GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken
    begin
        exit(RestClient.GetAsJSon(RequestUri));
    end;

    procedure GetUserSettings(UserSecurityId: Guid; var TempUserSettingsRecord: Record "User Settings" temporary)
    var
        UserSettings: Codeunit "User Settings";
    begin
        UserSettings.GetUserSettings(Database.UserSecurityID(), TempUserSettingsRecord);
    end;

    procedure ShouldSetCommonHeaders(): Boolean
    begin
        exit(true);
    end;
}