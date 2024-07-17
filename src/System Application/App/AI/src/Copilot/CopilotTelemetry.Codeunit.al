// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Telemetry;

/// <summary>
/// This codeunit is called from Platform.
/// </summary>
codeunit 7775 "Copilot Telemetry"
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotCapability: Enum "Copilot Capability";
        AppId: Guid;
        TelemetryFeedbackOnCopilotCapabilityLbl: Label 'Feedback on Copilot Capability.', Locked = true;
        TelemetryActionInvokedOnCopilotCapabilityLbl: Label 'Action invoked on Copilot Capability.', Locked = true;

    procedure SetCopilotCapability(NewCopilotCapability: Enum "Copilot Capability"; NewAppId: Guid)
    begin
        CopilotCapability := NewCopilotCapability;
        AppId := NewAppId;
    end;

    procedure SendCopilotFeedbackTelemetry(CustomDimensions: Dictionary of [Text, Text])
    var
        CopilotCapabilitiesImpl: Codeunit "Copilot Capability Impl";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not CustomDimensions.ContainsKey('Capability') then
            CopilotCapabilitiesImpl.AddTelemetryDimensions(CopilotCapability, AppId, CustomDimensions);
        FeatureTelemetry.LogUsage('0000LFO', CopilotCapabilitiesImpl.GetCopilotCategory(), TelemetryFeedbackOnCopilotCapabilityLbl, CustomDimensions);
    end;

    procedure SendCopilotActionInvokedTelemetry(CustomDimensions: Dictionary of [Text, Text])
    var
        CopilotCapabilitiesImpl: Codeunit "Copilot Capability Impl";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not CustomDimensions.ContainsKey('Capability') then
            CopilotCapabilitiesImpl.AddTelemetryDimensions(CopilotCapability, AppId, CustomDimensions);
        FeatureTelemetry.LogUsage('0000LLW', CopilotCapabilitiesImpl.GetCopilotCategory(), TelemetryActionInvokedOnCopilotCapabilityLbl, CustomDimensions);
    end;
}