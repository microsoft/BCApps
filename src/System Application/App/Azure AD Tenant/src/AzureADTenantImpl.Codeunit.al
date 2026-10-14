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
        CountryLetterCodeErr: Label 'Failed to retrieve the Microsoft Entra tenant country letter code.';
        PreferredLanguageErr: Label 'Failed to retrieve the Microsoft Entra tenant preferred language code.';
        VerifiedDomainsErr: Label 'Failed to retrieve the Microsoft Entra tenant verified domains.';

    procedure GetAadTenantId(): Text
    var
        TenantIdValue: Text;
        EntraTenantIdAsGuid: Guid;
    begin
        NavTenantSettingsHelper.TryGetStringTenantSetting('AADTENANTID', TenantIdValue);

        if Evaluate(EntraTenantIdAsGuid, TenantIdValue) then
            exit(LowerCase(Format(EntraTenantIdAsGuid, 0, 4)));

        exit(TenantIdValue);
    end;

    procedure GetAadTenantDomainName(): Text;
    begin
        Initialize();
        if not IsNull(TenantInfo) then
            exit(TenantInfo.InitialDomain());

        Error(TenantDomainNameErr);
    end;

    procedure GetCountryLetterCode(): Code[2];
    begin
        Initialize();
        if not IsNull(TenantInfo) then
            exit(CopyStr(TenantInfo.CountryLetterCode(), 1, 2));

        Error(CountryLetterCodeErr);
    end;

    procedure GetPreferredLanguage(): Code[2];
    begin
        Initialize();
        if not IsNull(TenantInfo) then
            exit(CopyStr(TenantInfo.PreferredLanguage(), 1, 2));

        Error(PreferredLanguageErr);
    end;

    procedure IsVerifiedDomain(Domain: Text): Boolean
    var
        VerifiedDomain: DotNet VerifiedDomainInfo;
        VerifiedDomains: DotNet GenericIEnumerable1;
        VerifiedDomainName: Text;
    begin
        Initialize();
        if IsNull(TenantInfo) then
            Error(VerifiedDomainsErr);

        VerifiedDomains := TenantInfo.VerifiedDomains();
        if IsNull(VerifiedDomains) then
            exit(false);

        foreach VerifiedDomain in VerifiedDomains do
            if not IsNull(VerifiedDomain) then begin
                VerifiedDomainName := VerifiedDomain.Name();
                if (VerifiedDomainName <> '') and (LowerCase(VerifiedDomainName) = LowerCase(Domain)) then
                    exit(true);
            end;
    end;

    procedure GetPowerPlatformTenantURL(): Text
    var
        PowerPlatformApiWrapper: dotnet "PowerPlatformApiWrapper";
    begin
        if GetAadTenantId() = '' then
            exit('');

        exit(PowerPlatformApiWrapper.GetPowerPlatformTenantUrl(GetAadTenantId()));
    end;

    local procedure Initialize()
    begin
        if IsNull(TenantInfo) then
            AzureADGraph.GetTenantDetail(TenantInfo);
    end;
}
