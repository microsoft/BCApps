// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.API.Codeunits;

using System.Azure.Identity;
using System.Environment;

/// <summary>
/// API codeunit exposing environment, tenant and license context as non-data-bound (unbound) reads.
/// Wraps "Environment Information" (457), "Azure AD Tenant" (433) and "Tenant License State" (2300).
/// </summary>
/// <remarks>TODO(AB#641822): decorate with the API codeunit subtype (microsoft/codeunits) when the platform ships it.</remarks>
codeunit 6010 "Environment API"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>Returns whether the environment is a production environment.</summary>
    procedure IsProduction(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsProduction());
    end;

    /// <summary>Returns whether the environment is a sandbox environment.</summary>
    procedure IsSandbox(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSandbox());
    end;

    /// <summary>Returns whether the solution is running as SaaS.</summary>
    procedure IsSaaS(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSaaS());
    end;

    /// <summary>Returns the name of the environment.</summary>
    procedure GetEnvironmentName(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.GetEnvironmentName());
    end;

    /// <summary>Returns the application family of the environment.</summary>
    procedure GetApplicationFamily(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.GetApplicationFamily());
    end;

    /// <summary>Returns the installed version of the app with the given ID.</summary>
    /// <param name="AppID">The app ID.</param>
    /// <returns>The installed major version, or 0 if not installed.</returns>
    procedure VersionInstalled(AppID: Guid): Integer
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.VersionInstalled(AppID));
    end;

    /// <summary>Returns the Microsoft Entra (Azure AD) tenant ID.</summary>
    procedure GetAadTenantId(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetAadTenantId());
    end;

    /// <summary>Returns the Microsoft Entra (Azure AD) tenant domain name.</summary>
    procedure GetAadTenantDomainName(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetAadTenantDomainName());
    end;

    /// <summary>Returns the tenant's country/region letter code.</summary>
    procedure GetCountryLetterCode(): Code[2]
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetCountryLetterCode());
    end;

    /// <summary>Returns the tenant's preferred language code.</summary>
    procedure GetPreferredLanguage(): Code[2]
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetPreferredLanguage());
    end;

    /// <summary>Returns the current tenant license state.</summary>
    procedure GetLicenseState(): Enum "Tenant License State"
    var
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        exit(TenantLicenseState.GetLicenseState());
    end;

    /// <summary>Returns whether the tenant is in trial mode.</summary>
    procedure IsTrialMode(): Boolean
    var
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        exit(TenantLicenseState.IsTrialMode());
    end;

    /// <summary>Returns whether the tenant is in paid mode.</summary>
    procedure IsPaidMode(): Boolean
    var
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        exit(TenantLicenseState.IsPaidMode());
    end;

    /// <summary>Returns the start date of the current license period.</summary>
    procedure GetStartDate(): DateTime
    var
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        exit(TenantLicenseState.GetStartDate());
    end;

    /// <summary>Returns the end date of the current license period.</summary>
    procedure GetEndDate(): DateTime
    var
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        exit(TenantLicenseState.GetEndDate());
    end;
}
