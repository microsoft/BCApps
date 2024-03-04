codeunit 326 "No. Series Copilot Installer"
{
    Subtype = Install;
    InherentPermissions = X;
    InherentEntitlements = X;

    trigger OnInstallAppPerDatabase()
    var
        NoSeriesCopilotRegister: Codeunit "No. Series Copilot Register";
    begin
        NoSeriesCopilotRegister.RegisterCapability();
    end;
}