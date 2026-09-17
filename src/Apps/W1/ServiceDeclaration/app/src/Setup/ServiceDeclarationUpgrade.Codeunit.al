// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using System.Upgrade;

codeunit 5016 "Service Declaration Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeServDeclSetup();
    end;

    local procedure UpgradeServDeclSetup()
    var
        ServDeclSetup: Record "Service Declaration Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetServDeclSetupUpgradeTag()) then
            exit;

        if ServDeclSetup.Get() then begin
            ServDeclSetup.Validate("Enable Serv. Trans. Types", true);
            ServDeclSetup.Validate("Show Serv. Decl. Overview", true);
            ServDeclSetup.Modify(true);
        end;

        UpgradeTag.SetUpgradeTag(GetServDeclSetupUpgradeTag());
    end;

    local procedure GetServDeclSetupUpgradeTag(): Code[250];
    begin
        exit('MS-437878-UpgradeServDeclSetup-20221109');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetServDeclSetupUpgradeTag());
    end;
}
