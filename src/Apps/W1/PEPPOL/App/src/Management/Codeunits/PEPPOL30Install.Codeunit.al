codeunit 37215 "PEPPOL30 Install"
{
    Access = Internal;
    Subtype = Install;
    
    trigger OnInstallAppPerCompany()
    var
        PEPPOL30Initialize: Codeunit "PEPPOL30 Initialize";
    begin
        PEPPOL30Initialize.CreateElectronicDocumentFormats();
    end;
}