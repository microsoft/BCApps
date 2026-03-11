// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

using System.Upgrade;

codeunit 1597 "Email Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    trigger OnUpgradePerCompany()
    var
        EmailInstaller: Codeunit "Email Installer";
    begin
        EmailInstaller.AddRetentionPolicyAllowedTables(); // also sets the tag
        SetDefaultEmailViewPolicy(Enum::"Email View Policy"::OwnEmails); // Default record is OwnEmails for existing tenants (to avoid breaking user experience)
        SetDefaultEmailMaxConcurrencyLimit(); // Default record is 3 for existing tenants (to avoid breaking user experience)
    end;

    local procedure SetDefaultEmailViewPolicy(DefaultEmailViewPolicy: Enum "Email View Policy")
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        EmailViewPolicy: Codeunit "Email View Policy";
    begin
        if UpgradeTag.HasUpgradeTag(GetDefaultEmailViewPolicyUpgradeTag()) then
            exit;

        EmailViewPolicy.CheckForDefaultEntry(DefaultEmailViewPolicy);

        UpgradeTag.SetUpgradeTag(GetDefaultEmailViewPolicyUpgradeTag());
    end;

    local procedure SetDefaultEmailMaxConcurrencyLimit()
    var
        EmailRateLimit: Record "Email Rate Limit";
        UpgradeTag: Codeunit "Upgrade Tag";
        EmailRateLimitImpl: Codeunit "Email Rate Limit Impl.";
    begin
        if UpgradeTag.HasUpgradeTag(GetDefaultEmailMaxConcurrencyLimitUpgradeTag()) then
            exit;

        EmailRateLimit.SetRange("Concurrency Limit", 0);
        if not EmailRateLimit.IsEmpty() then
            EmailRateLimit.ModifyAll("Concurrency Limit", EmailRateLimitImpl.GetDefaultConcurrencyLimit());

        UpgradeTag.SetUpgradeTag(GetDefaultEmailMaxConcurrencyLimitUpgradeTag());
    end;

    local procedure GetDefaultEmailViewPolicyUpgradeTag(): Code[250]
    begin
        exit('MS-445654-DefaultEmailViewPolicyChanged-20220109');
    end;

    local procedure GetDefaultEmailMaxConcurrencyLimitUpgradeTag(): Code[250]
    begin
        exit('MS-592720-DefaultEmailMaxConcurrencyLimitChanged-20250723');
    end;

    procedure GetEmailTablesAddedToAllowedListUpgradeTag(): Code[250]
    begin
        exit('MS-373161-EmailLogEntryAdded-20201005');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetDefaultEmailViewPolicyUpgradeTag()) then
            PerCompanyUpgradeTags.Add(GetDefaultEmailViewPolicyUpgradeTag());
        if not UpgradeTag.HasUpgradeTag(GetDefaultEmailMaxConcurrencyLimitUpgradeTag()) then
            PerCompanyUpgradeTags.Add(GetDefaultEmailMaxConcurrencyLimitUpgradeTag());
        if not UpgradeTag.HasUpgradeTag(GetEmailTablesAddedToAllowedListUpgradeTag()) then
            PerCompanyUpgradeTags.Add(GetEmailTablesAddedToAllowedListUpgradeTag());
    end;
}