// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Privacy;

using System.Upgrade;

codeunit 1567 "System Upgrade Privacy Notices"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    begin
        UpgradeTeamsPrivacyNotice();
        UpgradeMicrosoftLearnPrivacyNotice();
    end;

    local procedure UpgradeTeamsPrivacyNotice()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        UpgradeTag: Codeunit "Upgrade Tag";
        SystemPrivacyNoticeReg: Codeunit "System Privacy Notice Reg.";
    begin
        if UpgradeTag.HasUpgradeTag(GetTeamsPrivacyNoticeUpgradeTag()) then
            exit;

        PrivacyNotice.CreateDefaultPrivacyNotices();

        PrivacyNotice.SetApprovalState(SystemPrivacyNoticeReg.GetTeamsPrivacyNoticeId(), "Privacy Notice Approval State"::Agreed);

        UpgradeTag.SetUpgradeTag(GetTeamsPrivacyNoticeUpgradeTag());
    end;

    local procedure UpgradeMicrosoftLearnPrivacyNotice()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        UpgradeTag: Codeunit "Upgrade Tag";
        SystemPrivacyNoticeReg: Codeunit "System Privacy Notice Reg.";
    begin
        if UpgradeTag.HasUpgradeTag(GetMicrosoftLearnPrivacyNoticeUpgradeTag()) then
            exit;

        PrivacyNotice.CreateDefaultPrivacyNotices();

        PrivacyNotice.SetApprovalState(SystemPrivacyNoticeReg.GetMicrosoftLearnID(), "Privacy Notice Approval State"::Agreed);

        UpgradeTag.SetUpgradeTag(GetMicrosoftLearnPrivacyNoticeUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetTeamsPrivacyNoticeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetMicrosoftLearnPrivacyNoticeUpgradeTag());
    end;

    local procedure GetTeamsPrivacyNoticeUpgradeTag(): Code[250]
    begin
        exit('MS-427298-PrivacyNoticeApproveTeams-20220222');
    end;

    local procedure GetMicrosoftLearnPrivacyNoticeUpgradeTag(): Code[250]
    begin
        exit('MS-502565-PrivacyNoticeApproveMicrosoftLearn-20250212');
    end;
}
