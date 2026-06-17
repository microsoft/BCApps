// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.ApplicationAreas;

#if not CLEAN29
using Microsoft.Manufacturing.Setup;
#endif
using System.Environment.Configuration;

codeunit 99001571 "Subc. Application Area Mgmt."
{
    Access = Internal;

    internal procedure IsSubcontractingApplicationAreaEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if ApplicationAreaMgmtFacade.GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName()) then
            exit(ApplicationAreaSetup.Subcontracting);
    end;

    internal procedure RefreshExperienceTierCurrentCompany()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", 'OnGetPremiumExperienceAppAreas', '', false, true)]
    local procedure HandleOnGetPremiumExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary);
#if not CLEAN29
    var
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
    begin
#if not CLEAN29
        if ManufacturingSetup.Get() then
#pragma warning disable AL0432
            TempApplicationAreaSetup.Subcontracting := not ManufacturingSetup."Legacy Subcontracting";
#pragma warning restore AL0432
#else
        TempApplicationAreaSetup.Subcontracting := true;
#endif

    end;
}
