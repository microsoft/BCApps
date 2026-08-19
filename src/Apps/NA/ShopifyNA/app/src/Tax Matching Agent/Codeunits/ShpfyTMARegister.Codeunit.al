// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.AI;
using System.Environment;
using System.Telemetry;

/// <summary>
/// Codeunit Shpfy TMA Register (ID 30470).
/// Registers the Copilot capability and handles the OnRegisterCopilotCapability event.
/// </summary>
codeunit 30470 "Shpfy TMA Register"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2179727', Locked = true;
        FeatureNameTxt: Label 'Shopify Tax Matching Agent', Locked = true;

    procedure RegisterCopilotCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Shopify Tax Matching Agent") then begin
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Shopify Tax Matching Agent", LearnMoreUrlTxt);
            FeatureTelemetry.LogUptake('0000UMZ', FeatureNameTxt, Enum::"Feature Uptake Status"::"Set up");
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
}
