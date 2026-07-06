namespace System.Environment.Configuration;
#if not CLEAN28
using Microsoft.Manufacturing.Setup;
#endif

codeunit 9181 "Application Area Localization"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetBasicExperienceAppAreas', '', false, false)]
    local procedure OnGetBasicExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup.VAT := true;
        TempApplicationAreaSetup."Basic EU" := true;
        TempApplicationAreaSetup."Basic IT" := true;
    end;

#if not CLEAN28
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetPremiumExperienceAppAreas', '', false, false)]
    local procedure OnGetPremiumExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        SetLegacySubcontractingApplicationArea(TempApplicationAreaSetup);
    end;

    local procedure SetLegacySubcontractingApplicationArea(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.SetLoadFields("Legacy Subcontracting");
        if ManufacturingSetup.Get() then
            TempApplicationAreaSetup."Legacy Subcontracting" := ManufacturingSetup."Legacy Subcontracting";
    end;
#endif
}
