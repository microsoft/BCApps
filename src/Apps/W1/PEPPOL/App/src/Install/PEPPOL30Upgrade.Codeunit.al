// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;
using System.Upgrade;

codeunit 37215 "PEPPOL30 Upgrade"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;


    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PEPPOL30Initialize: Codeunit "PEPPOL30 Initialize";
    begin
        if UpgradeTag.HasUpgradeTag(InitialUpgradeTag()) then
            exit;

        PEPPOL30Initialize.CreateElectronicDocumentFormats();
        UpgradeTag.SetUpgradeTag(InitialUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure OnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(InitialUpgradeTag());
    end;

    local procedure InitialUpgradeTag(): Text[250]
    begin
        exit('MS-121225-PEPPOL1P-APP-INSTALL');
    end;

}