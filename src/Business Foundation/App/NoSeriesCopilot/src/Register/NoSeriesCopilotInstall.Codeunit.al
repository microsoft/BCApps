codeunit 290 "No. Series Copilot Install"
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