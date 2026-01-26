#pragma warning disable AA0247
#if not CLEAN26
codeunit 104152 "Copy Line Descr. To G/L Entry"
{
    Subtype = Upgrade;
    ObsoleteReason = 'It is before 15.0 change, upgrade already happened.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        SetCopyLineDescrToGLEntries();
    end;

    local procedure SetCopyLineDescrToGLEntries()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Bug ugprade tag or remove
        if PurchasesPayablesSetup.Get() then begin
            PurchasesPayablesSetup."Copy Line Descr. to G/L Entry" := true;
            PurchasesPayablesSetup.Modify();
        end;
    end;
}
#endif
