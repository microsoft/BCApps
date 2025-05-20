// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Telemetry;
using System.Globalization;

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
        TelemetryAllowDataMovementUpdatedLbl: Label 'Allow data movement was updated.', Locked = true;

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

    procedure SendCopilotDataMovementUpdatedTelemetry()
    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        AllowDataMovement: Boolean;
    begin
        CopilotCapabilityImpl.GetDataMovementAllowed(AllowDataMovement);

        SendCopilotDataMovementUpdatedTelemetry(AllowDataMovement);
    end;

    procedure SendCopilotDataMovementUpdatedTelemetry(AllowDataMovement: Boolean)
    var
        CopilotCapabilitiesImpl: Codeunit "Copilot Capability Impl";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Language: Codeunit Language;
        CustomDimensions: Dictionary of [Text, Text];
        WithinGeo: Boolean;
        WithinEUDB: Boolean;
        SavedGlobalLanguageId: Integer;
    begin
        CopilotCapabilitiesImpl.CheckGeoAndEUDB(WithinGeo, WithinEUDB);

        SavedGlobalLanguageId := GlobalLanguage();

        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        CustomDimensions.Add('Category', CopilotCapabilitiesImpl.GetCopilotCategory());
        CustomDimensions.Add('AllowDataMovement', Format(AllowDataMovement));
        CustomDimensions.Add('WithinGeo', Format(WithinGeo));
        CustomDimensions.Add('WithinEUDB', Format(WithinEUDB));

        GlobalLanguage(SavedGlobalLanguageId);

        FeatureTelemetry.LogUsage('0000OQK', CopilotCapabilitiesImpl.GetCopilotCategory(), TelemetryAllowDataMovementUpdatedLbl, CustomDimensions);
    end;
}