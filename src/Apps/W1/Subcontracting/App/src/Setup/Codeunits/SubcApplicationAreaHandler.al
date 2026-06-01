// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Company;
using Microsoft.Manufacturing.Setup;
using System.Environment.Configuration;

codeunit 99001568 "Subc. Application Area Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade",
        OnGetPremiumExperienceAppAreas, '', false, false)]
    local procedure OnGetPremiumExperienceAppAreasSubscriber(var TempApplicationAreaSetup: Record "Application Area Setup")
    begin
        SetApplicationArea(TempApplicationAreaSetup);
    end;

    local procedure SetApplicationArea(var TempApplicationAreaSetup: Record "Application Area Setup")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.SetLoadFields("Legacy Subcontracting");
        if ManufacturingSetup.Get() then
            TempApplicationAreaSetup."Subcontracting" := not ManufacturingSetup."Legacy Subcontracting";
    end;

    internal procedure UpdateApplicationArea()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;
}
