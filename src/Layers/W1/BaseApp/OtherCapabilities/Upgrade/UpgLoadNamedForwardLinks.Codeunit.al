// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Utilities;
using System.Environment;
using System.Upgrade;

codeunit 104050 "Upg Load Named Forward Links"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        LoadForwardLinks();
    end;

    local procedure LoadForwardLinks()
    var
        NamedForwardLink: Record "Named Forward Link";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetLoadNamedForwardLinksUpgradeTag()) then
            exit;

        NamedForwardLink.Load();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetLoadNamedForwardLinksUpgradeTag());
    end;
}