// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Identity;

using System;

codeunit 3705 "Azure AD Tenant Impl."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AzureADGraph: Codeunit "Azure AD Graph";
        TenantInfo: DotNet TenantInfo;
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
        TenantDomainNameErr: Label 'Failed to retrieve the Microsoft Entra tenant domain name.';
        CountryLetterCodeErr: Label 'Failed to retrieve the Microsoft Entra tenant domain name.';
        PreferedLanguageErr: Label 'Failed to retrieve the Microsoft Entra tenant domain name.';

    procedure GetAadTenantId() TenantIdValue: Text
    begin
        NavTenantSettingsHelper.TryGetStringTenantSetting('AADTENANTID', TenantIdValue);
    end;

    procedure GetAadTenantDomainName(): Text;
    begin
        Initialize();
        if not IsNull(TenantInfo) then
            exit(TenantInfo.InitialDomain());

        Error(TenantDomainNameErr);
    end;

    procedure GetCountryLetterCode(): Text;
    begin
        Initialize();
        if not IsNull(TenantInfo) then
            exit(TenantInfo.CountryLetterCode());

        Error(CountryLetterCodeErr);
    end;

    procedure GetPreferredLanguage(): Text;
    begin
        Initialize();
        if not IsNull(TenantInfo) then
            exit(TenantInfo.PreferredLanguage());

        Error(PreferedLanguageErr);
    end;

    local procedure Initialize()
    begin
        if IsNull(TenantInfo) then
            AzureADGraph.GetTenantDetail(TenantInfo);
    end;
}

