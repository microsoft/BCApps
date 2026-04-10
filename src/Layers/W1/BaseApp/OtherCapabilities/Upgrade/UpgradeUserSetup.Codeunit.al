// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.EMail;
using System.Security.AccessControl;
using System.Security.User;
using System.Upgrade;

codeunit 104058 "Upgrade User Setup"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeUserSetup();
    end;

    local procedure UpgradeUserSetup()
    var
        User: Record User;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPopulateUserSetupEmailUpgradeTag()) then
            exit;

        User.SetFilter("Contact Email", '<>%1', '');
        if User.FindSet() then
            repeat
                SetEmailOnRecord(User);
            until User.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPopulateUserSetupEmailUpgradeTag());
    end;

    local procedure SetEmailOnRecord(User: Record User)
    var
        UserSetup: Record "User Setup";
        MailManagement: Codeunit "Mail Management";
        UserSetupEmail: Text[100];
    begin
        if not UserSetup.Get(User."User Name") then
            exit;

        if UserSetup."E-Mail" <> '' then
            exit;

        UserSetupEmail := CopyStr(User."Contact Email", 1, MaxStrLen(UserSetup."E-Mail"));

        if not MailManagement.CheckValidEmailAddress(UserSetupEmail) then
            exit;

        UserSetup."E-Mail" := UserSetupEmail;
        UserSetup.Modify(false);
    end;
}