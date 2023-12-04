// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Identity;

/// <summary>
/// Exposes functionality to fetch attributes concerning the current tenant.
/// </summary>
codeunit 433 "Azure AD Tenant"
{
    Access = Public;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AzureADTenantImpl: Codeunit "Azure AD Tenant Impl.";

    /// <summary>
    /// Gets the Microsoft Entra tenant ID.
    /// </summary>
    /// <returns>If it cannot be found, an empty string is returned.</returns>
    procedure GetAadTenantId(): Text
    begin
        exit(AzureADTenantImpl.GetAadTenantId());
    end;

    /// <summary>
    /// Gets the Microsoft Entra tenant domain name.
    /// If the Microsoft Graph API cannot be reached, the error is displayed.
    /// </summary>
    /// <returns>The Microsoft Entra tenant Domain Name.</returns>
    /// <error>Cannot retrieve the Microsoft Entra tenant domain name.</error>
    procedure GetAadTenantDomainName(): Text
    begin
        exit(AzureADTenantImpl.GetAadTenantDomainName());
    end;

    /// <summary>
    /// Gets the current Microsoft Entra tenant registered country letter code
    /// If the Microsoft Graph API cannot be reached, the error is displayed.
    /// <summary>
    /// <returns>Country letter code</returns>
    /// <see cref="Microsoft Admin Cententer to view or edit Organizational Information"/>
    /// <error>Cannot retrieve the Microsoft Entra tenant country letter code.</error>
    procedure GetCountryLetterCode(): Text;
    var
        AzureADGraph: Codeunit "Azure AD Graph";
        TenantInfo: DotNet TenantInfo;
    begin
        AzureADGraph.GetTenantDetail(TenantInfo);
        if not IsNull(TenantInfo) then
            exit(TenantInfo.CountryLetterCode());

        Error(TenantDomainNameErr);
    end;

    /// <summary>
    /// Gets the current Microsoft Entra tenant registered preferred language
    /// If the Microsoft Graph API cannot be reached, the error is displayed.
    /// <summary>
    /// <see cref="Microsoft Admin Cententer to view or edit Organizational Information"/>
    /// <returns>Preferred Language</returns>
    /// <error>Cannot retrieve the Microsoft Entra tenant preferred language.</error>
    procedure GetPreferredLanguage(): Text;
    var
        AzureADGraph: Codeunit "Azure AD Graph";
        TenantInfo: DotNet TenantInfo;
    begin
        AzureADGraph.GetTenantDetail(TenantInfo);
        if not IsNull(TenantInfo) then
            exit(TenantInfo.PreferredLanguage());

        Error(TenantDomainNameErr);
    end;
}

