codeunit 128000 InstallCodeunit
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        UPGCRMConnectionSetup: Record "UPG - CRM Connection Setup";
        myInfo: ModuleInfo;
    begin
        if not CRMConnectionSetup.get() then
            CRMConnectionSetup.Insert();

        CRMConnectionSetup."Last Update Invoice Entry No." := 15;
        CRMConnectionSetup.Modify();

        UPGCRMConnectionSetup.TransferFields(CRMConnectionSetup, true);
        UPGCRMConnectionSetup.Insert();
    end;
}