#pragma warning disable AA0247
codeunit 104170 "UPG SEPA NL"
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
         
        UpgradeLocalSEPAInstrPrtyInGenLedgSetup();
    end;

    local procedure UpgradeLocalSEPAInstrPrtyInGenLedgSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetLocalSEPAInstrPrtyUpgradeTag()) then
            exit;

        if GeneralLedgerSetup.Get() then begin
            GeneralLedgerSetup.Validate("Local SEPA Instr. Priority", true);
            GeneralLedgerSetup.Modify(true);
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetLocalSEPAInstrPrtyUpgradeTag());
    end;

}

