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

    local procedure Initialize()
    begin
        if IsNull(TenantInfo) then
            AzureADGraph.GetTenantDetail(TenantInfo);
    end;
}

