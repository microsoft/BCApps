namespace System.Environment.Configuration;

codeunit 9181 "Application Area Localization"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetBasicExperienceAppAreas', '', false, false)]
    local procedure OnGetBasicExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."Sales Tax" := true;
        TempApplicationAreaSetup."Basic US" := true;
    end;
}

