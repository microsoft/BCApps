
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

using System.Environment.Configuration;
using System.RestClient;

/// <summary>
/// Interface for managing dependencies to the AppSource Product Manager codeunit.
/// </summary>
interface "AppSource Product Manager Dependencies"
{
    Access = Internal;

    // Dependency to Azure AD Tenant
    procedure GetCountryLetterCode(): Code[2];
    procedure GetPreferredLanguage(): Text;

    // Dependency to Environment Information 
    procedure GetApplicationFamily(): Text;
    procedure IsSaas(): Boolean;

    // Dependency to Language 
    procedure GetFormatRegionOrDefault(FormatRegion: Text[80]): Text;

    // Rest client override
    procedure GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken;
    procedure ShouldSetCommonHeaders(): Boolean;

    // Dependency to User Settings
    procedure GetUserSettings(UserSecurityID: Guid; var TempUserSettingsRecord: Record "User Settings" temporary);
}
