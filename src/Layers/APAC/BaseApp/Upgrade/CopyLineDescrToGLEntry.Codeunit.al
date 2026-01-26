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
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        // Bug ugprade tag or remove
        if SalesSetup.Get() then begin
            SalesSetup."Copy Line Descr. to G/L Entry" := true;
            SalesSetup.Modify();
        end;

        if PurchSetup.Get() then begin
            PurchSetup."Copy Line Descr. to G/L Entry" := true;
            PurchSetup.Modify();
        end;
    end;
}
#endif
