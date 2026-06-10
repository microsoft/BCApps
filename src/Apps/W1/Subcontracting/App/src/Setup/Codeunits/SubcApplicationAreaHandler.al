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
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetPremiumExperienceAppAreas, '', false, false)]
    local procedure OnGetPremiumExperienceAppAreasSubscriber(var TempApplicationAreaSetup: Record "Application Area Setup")
    begin
#if not CLEAN29
        SetApplicationArea(TempApplicationAreaSetup);
#else
        TempApplicationAreaSetup."Subcontracting" := TempApplicationAreaSetup.Manufacturing; 
#endif
    end;

#if not CLEAN29
    local procedure SetApplicationArea(var TempApplicationAreaSetup: Record "Application Area Setup")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
#pragma warning disable AL0432
        ManufacturingSetup.SetLoadFields("Legacy Subcontracting");
#pragma warning restore AL0432
        if ManufacturingSetup.Get() then
#pragma warning disable AL0432
            TempApplicationAreaSetup."Subcontracting" := not ManufacturingSetup."Legacy Subcontracting";
#pragma warning restore AL0432
    end;
#endif

    internal procedure UpdateApplicationArea()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;
}
