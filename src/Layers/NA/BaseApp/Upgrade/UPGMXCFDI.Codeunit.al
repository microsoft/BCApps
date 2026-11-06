#pragma warning disable AA0247
codeunit 104151 "UPG. MX CFDI"
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

        UpdateSATCatalogs();
        UpdateCFDIFields();
        UpdateCFDIEnabled();
        UpgradePACWebServiceDetails();
    end;

    local procedure UpdateSATCatalogs()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetSATPaymentCatalogsSwapTag()) then
            exit;

        Codeunit.Run(Codeunit::"Update SAT Payment Catalogs");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetSATPaymentCatalogsSwapTag());
    end;

    local procedure UpdateCFDIFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCFDIPurposeRelationFieldsDocUpdateTag()) then
            exit;

        Codeunit.Run(Codeunit::"Update CFDI Fields Sales Doc");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCFDIPurposeRelationFieldsDocUpdateTag());
    end;

    local procedure UpdateCFDIEnabled()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCFDIEnableOptionUpgradeTag()) then
            exit;

        if GeneralLedgerSetup.Get() then begin
            GeneralLedgerSetup."CFDI Enabled" :=
                GeneralLedgerSetup."PAC Environment" in [GeneralLedgerSetup."PAC Environment"::Test, GeneralLedgerSetup."PAC Environment"::Production];
            GeneralLedgerSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCFDIEnableOptionUpgradeTag());
    end;

    local procedure UpgradePACWebServiceDetails()
    var
        SATUtilities: Codeunit "SAT Utilities";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetPACWebServiceDetailsUpgradeTag()) then
            exit;

        SATUtilities.PopulatePACWebServiceData();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetPACWebServiceDetailsUpgradeTag());
    end;





}

