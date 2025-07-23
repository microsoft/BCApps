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
        // go through the record and set the default value
        if EmailRateLimit.FindSet() then
            repeat
                if (EmailRateLimit."Concurrency Limit" = 0) then
                    EmailRateLimit."Concurrency Limit" := EmailRateLimitImpl.GetDefaultConcurrencyLimit(); // set default value
                EmailRateLimit.Modify();
            until EmailRateLimit.Next() = 0;

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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetDefaultEmailViewPolicyUpgradeTag()) then
            PerCompanyUpgradeTags.Add(GetDefaultEmailViewPolicyUpgradeTag());
        if not UpgradeTag.HasUpgradeTag(GetDefaultEmailMaxConcurrencyLimitUpgradeTag()) then
            PerCompanyUpgradeTags.Add(GetDefaultEmailMaxConcurrencyLimitUpgradeTag());
    end;
}