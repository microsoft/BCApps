// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.ApplicationAreas;

using Microsoft.QualityManagement.Setup.Setup;
using System.Environment.Configuration;

codeunit 20420 "Qlty. Application Area Mgmt."
{
    Access = Internal;

    internal procedure IsQualityManagementApplicationAreaEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if ApplicationAreaMgmtFacade.GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName()) then
            exit(ApplicationAreaSetup."Quality Management");
    end;

    internal procedure RefreshExperienceTierCurrentCompany()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;

    #region Event Subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", 'OnGetEssentialExperienceAppAreas', '', false, true)]
    local procedure HandleOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary);
    begin
        AutoEnableAppAreaForUpgrades(TempApplicationAreaSetup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", 'OnGetPremiumExperienceAppAreas', '', false, true)]
    local procedure HandleOnGetPremiumExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary);
    begin
        AutoEnableAppAreaForUpgrades(TempApplicationAreaSetup);
    end;

    #endregion Event Subscribers

    local procedure AutoEnableAppAreaForUpgrades(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        TempApplicationAreaSetup."Quality Management" := true;

        if not QltyManagementSetup.ReadPermission() then
            exit;

        if QltyManagementSetup.Get() then;
        TempApplicationAreaSetup."Quality Management" := QltyManagementSetup.Visibility = QltyManagementSetup.Visibility::Show;
    end;
}
