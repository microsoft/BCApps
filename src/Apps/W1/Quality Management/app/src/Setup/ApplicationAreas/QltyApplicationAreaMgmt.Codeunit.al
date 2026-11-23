// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.ApplicationAreas;

using System.Environment.Configuration;

codeunit 20420 "Qlty. Application Area Mgmt."
{
    Access = Internal;

    /// <summary>
    /// Determines whether the Quality Management application area is enabled for the current company.
    /// </summary>
    /// <returns>True if the Quality Management application area is enabled; otherwise, false.</returns>
    internal procedure IsQualityManagementApplicationAreaEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if ApplicationAreaMgmtFacade.GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName()) then
            exit(ApplicationAreaSetup."Quality Management");
    end;

    /// <summary>
    /// Refreshes the experience tier for the current company.
    /// </summary>
    internal procedure RefreshExperienceTierCurrentCompany()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;

    #region Event Subscribers

    /// <summary>
    /// Enables the Quality Management application area for the essential experience tier.
    /// </summary>
    /// <param name="TempApplicationAreaSetup">The temporary application area setup to update.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", 'OnGetEssentialExperienceAppAreas', '', false, true)]
    local procedure HandleOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary);
    begin
        TempApplicationAreaSetup."Quality Management" := true;
    end;

    /// <summary>
    /// Enables the Quality Management application area for the premium experience tier.
    /// </summary>
    /// <param name="TempApplicationAreaSetup">The temporary application area setup to update.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", 'OnGetPremiumExperienceAppAreas', '', false, true)]
    local procedure HandleOnGetPremiumExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary);
    begin
        TempApplicationAreaSetup."Quality Management" := true;
    end;

    #endregion Event Subscribers
}
