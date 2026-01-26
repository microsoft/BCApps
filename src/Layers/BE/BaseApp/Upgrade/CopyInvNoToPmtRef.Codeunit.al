#pragma warning disable AA0247
codeunit 104153 "Copy Inv. No. To Pmt. Ref"
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
            
        SetCopyInvNoToPmtRef();
    end;

    local procedure SetCopyInvNoToPmtRef()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCopyInvNoToPmtRefTag()) then
            exit;

        if PurchasesPayablesSetup.Get() then begin
            PurchasesPayablesSetup."Copy Inv. No. To Pmt. Ref." := true;
            PurchasesPayablesSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCopyInvNoToPmtRefTag());
    end;
}

