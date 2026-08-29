// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.API.Codeunits;

using System.Azure.Identity;
using System.Environment;

/// <summary>
/// Provides read-only environment and installed app information for integrations.
/// </summary>
/// <remarks>
/// Until the API codeunit subtype is available, the Microsoft.API.Codeunits namespace publishes
/// this codeunit under the microsoft/codeunits/beta route.
/// </remarks>
codeunit 6010 "Environment API"
{
    Access = Public;
    InherentEntitlements = X;

    /// <summary>Gets the name of the environment.</summary>
    /// <returns>The environment name.</returns>
    procedure GetEnvironmentName(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.GetEnvironmentName());
    end;

    /// <summary>Checks whether the environment is a production environment.</summary>
    /// <returns>True for a production environment; otherwise, false.</returns>
    procedure IsProduction(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsProduction());
    end;

    /// <summary>Checks whether the environment is a sandbox environment.</summary>
    /// <returns>True for a sandbox environment; otherwise, false.</returns>
    procedure IsSandbox(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSandbox());
    end;

    /// <summary>Checks whether the environment is running as software as a service.</summary>
    /// <returns>True for a SaaS environment; otherwise, false.</returns>
    procedure IsSaaS(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSaaS());
    end;

    /// <summary>Gets the Microsoft Entra tenant ID.</summary>
    /// <returns>The tenant ID, or an empty string when it cannot be determined.</returns>
    procedure GetEntraTenantId(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetAadTenantId());
    end;

    /// <summary>Checks whether an app is installed.</summary>
    /// <param name="AppId">The app ID.</param>
    /// <returns>True when the app is installed; otherwise, false.</returns>
    procedure IsAppInstalled(AppId: Guid): Boolean
    var
        AppInfo: ModuleInfo;
    begin
        exit(NavApp.GetModuleInfo(AppId, AppInfo));
    end;

    /// <summary>Gets the installed version of an app.</summary>
    /// <param name="AppId">The app ID.</param>
    /// <returns>The complete app version.</returns>
    /// <error>The app is not installed.</error>
    procedure GetAppVersion(AppId: Guid): Text
    var
        AppInfo: ModuleInfo;
    begin
        if not NavApp.GetModuleInfo(AppId, AppInfo) then
            Error(AppNotInstalledErr, AppId);

        exit(Format(AppInfo.AppVersion()));
    end;

    var
        AppNotInstalledErr: Label 'The app with ID %1 is not installed.', Comment = '%1 = the app ID';
}
