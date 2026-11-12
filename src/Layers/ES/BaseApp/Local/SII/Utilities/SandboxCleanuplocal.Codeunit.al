#pragma warning disable AA0247
codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', true, false)]
    local procedure OnClearConfiguration(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        SIISetup: Record "SII Setup";
    begin
        if CompanyName() <> CompanyName then
            SIISetup.ChangeCompany(CompanyName);

        SIISetup.ModifyAll(Enabled, false);
    end;
}

