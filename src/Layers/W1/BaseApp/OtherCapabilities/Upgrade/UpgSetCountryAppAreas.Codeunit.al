// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Environment;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 104010 "Upg Set Country App Areas"
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

        SetCountryAppAreas();
    end;

    local procedure SetCountryAppAreas()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCountryApplicationAreasTag()) then
            exit;

        if ApplicationAreaSetup.GET() and ApplicationAreaSetup.Basic then begin
            ApplicationAreaSetup.VAT := true;
            ApplicationAreaSetup."Basic EU" := true;
            ApplicationAreaSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCountryApplicationAreasTag());
    end;
}

