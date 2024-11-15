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
    /// <returns>If the Entra tenant ID is a valid GUID, it will be returned in lowercase format and without brackets or parentheses (as per RFC4122 section 3), such as "f81d4fae-7dec-11d0-a765-00a0c91e6bf6". If it cannot be found, an empty string is returned.</returns>
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
    /// Gets the current Microsoft Entra tenant registered country letter code.
    /// Visit Microsoft Admin Cententer to view or edit Organizational Information.
    /// If the Microsoft Graph API cannot be reached, the error is displayed.
    /// </summary>
    /// <returns>Country or region abbreviation for the organization in ISO 3166-2 format.</returns>
    /// <error>Cannot retrieve the Microsoft Entra tenant country letter code.</error>
    procedure GetCountryLetterCode(): Code[2];
    begin
        exit(AzureADTenantImpl.GetCountryLetterCode());
    end;

    /// <summary>
    /// Gets the current Microsoft Entra tenant registered preferred language.
    /// Visit Microsoft Admin Cententer to view or edit Organizational Information.
    /// If the Microsoft Graph API cannot be reached, the error is displayed.
    /// </summary>
    /// <returns>The preferred language for the organization. Should follow ISO 639-1 Code; for example, en.</returns>
    /// <error>Cannot retrieve the Microsoft Entra tenant preferred language.</error>
    procedure GetPreferredLanguage(): Code[2];
    begin
        exit(AzureADTenantImpl.GetPreferredLanguage());
    end;
}

