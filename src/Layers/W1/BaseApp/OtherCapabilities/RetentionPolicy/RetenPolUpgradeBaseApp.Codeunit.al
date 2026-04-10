namespace System.DataAdministration;

using System.Environment;

codeunit 3996 "Reten. Pol. Upgrade - BaseApp"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerCompany()
    var
        RetenPolInstallBaseApp: Codeunit "Reten. Pol. Install - BaseApp";
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        RetenPolInstallBaseApp.AddAllowedTables(); // also sets the tag!
    end;
}