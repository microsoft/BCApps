namespace Microsoft.Integration.Shopify;

using System.AI;
// using System.Environment;
using System.Telemetry;

/// <summary>
/// Codeunit Shpfy Copilot Tax Register (ID 30470).
/// Registers the Copilot capability and handles the OnRegisterCopilotCapability event.
/// </summary>
codeunit 30470 "Shpfy Copilot Tax Register"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure RegisterCopilotCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        // EnvironmentInformation: Codeunit "Environment Information";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        // if not EnvironmentInformation.IsSaaSInfrastructure() then
        //     exit;

        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Shpfy Tax Matching") then begin
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Shpfy Tax Matching", LearnMoreUrlTxt);
            FeatureTelemetry.LogUptake('', FeatureNameTxt, Enum::"Feature Uptake Status"::"Set up");
        end;
    end;

    procedure FeatureName(): Text
    begin
        exit(FeatureNameTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", OnRegisterCopilotCapability, '', false, false)]
    local procedure HandleOnRegisterCopilotCapability()
    begin
        RegisterCopilotCapability();
    end;

    var
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2179727', Locked = true;
        FeatureNameTxt: Label 'Shopify Tax Jurisdiction Matching with AI', Locked = true;
}
