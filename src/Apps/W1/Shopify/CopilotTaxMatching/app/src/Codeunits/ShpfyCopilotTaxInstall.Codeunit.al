namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Copilot Tax Install (ID 30475).
/// Install codeunit that registers the Copilot capability.
/// </summary>
codeunit 30475 "Shpfy Copilot Tax Install"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
    begin
        CopilotTaxRegister.RegisterCopilotCapability();
    end;
}
