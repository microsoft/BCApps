#pragma warning disable AA0247
codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure OnClearConfiguration(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        if CompanyName() <> CompanyName then
            ElecTaxDeclarationSetup.ChangeCompany(CompanyName);

        ElecTaxDeclarationSetup.ModifyAll("Digipoort Client Cert. Name", '');
        ElecTaxDeclarationSetup.ModifyAll("Digipoort Service Cert. Name", '');
        ElecTaxDeclarationSetup.ModifyAll("Digipoort Delivery URL", '');
        ElecTaxDeclarationSetup.ModifyAll("Digipoort Status URL", '');
    end;
}

