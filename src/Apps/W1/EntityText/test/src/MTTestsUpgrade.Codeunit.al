namespace System.Text.Test;

codeunit 133556 "MT Tests Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        MTTestsInstall: Codeunit "MT Tests Install";
    begin
        MTTestsInstall.SetupTestData();
        MTTestsInstall.SetupTestSuites();
    end;
}
