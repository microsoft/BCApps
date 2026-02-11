// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Represents the AOAI Policy management for combining Harms Severity and XPIA Detection settings.
/// </summary>
codeunit 7787 "AOAI Policy Params"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AOAIPolicyParamsImpl: Codeunit "AOAI Policy Params Impl";

    /// <summary>
    /// Gets the current AOAI Policy Harms Severity setting.
    /// </summary>
    /// <returns>The current AOAI Policy Harms Severity.</returns>
    procedure GetHarmsSeverity(): Enum "AOAI Policy Harms Severity"
    begin
        exit(AOAIPolicyParamsImpl.GetHarmsSeverity());
    end;

    /// <summary>
    /// Gets the current AOAI Policy XPIA Detection setting.
    /// </summary>
    /// <returns>Gets the status of AOAI Policy XPIA Detection.</returns>
    procedure GetXPIADetection(): Boolean
    begin
        exit(AOAIPolicyParamsImpl.GetXPIADetection());
    end;

    /// <summary>
    /// Sets the AOAI Policy Harms Severity.
    /// </summary>
    /// <param name="HarmsSeverity">The AOAI Policy Harms Severity to set.</param>
    procedure SetHarmsSeverity(HarmsSeverity: Enum "AOAI Policy Harms Severity")
    begin
        AOAIPolicyParamsImpl.SetHarmsSeverity(HarmsSeverity);
    end;

    /// <summary>
    /// Sets the AOAI Policy XPIA Detection.
    /// </summary>
    /// <param name="IsEnabled">Enable/Disable AOAI Policy XPIA Detection</param>
    /// <remarks>When XPIA detection is enabled, use <see cref="AOAI Chat Messages.EnforceXPIADetection"/> to mark messages for XPIA detection.</remarks>
    procedure SetXPIADetection(IsEnabled: Boolean)
    begin
        AOAIPolicyParamsImpl.SetXPIADetection(IsEnabled);
    end;

    /// <summary>
    /// Gets the value for the custom AOAI policy, if set using SetCustomAOAIPolicy
    /// </summary>
    procedure GetCustomAOAIPolicy(): Text
    begin
        exit(AOAIPolicyParamsImpl.GetCustomAOAIPolicy());
    end;

    /// <summary>
    /// Sets a Custom AOAI policy.
    /// </summary>
    procedure SetCustomAOAIPolicy(CustomAOAIPolicyParams: Text)
    begin
        AOAIPolicyParamsImpl.SetCustomAOAIPolicy(CustomAOAIPolicyParams);
    end;

    /// <summary>
    /// Initializes the AOAI Policy parameters to their default values.
    /// </summary>
    procedure InitializeDefaults()
    begin
        AOAIPolicyParamsImpl.InitializeDefaults();
    end;

    /// <summary>
    /// Gets whether the current Azure AOAI policy is the default one.
    /// </summary>
    /// <returns>True if the current policy is the default; otherwise, false.</returns>
    procedure IsDefaultPolicy(): Boolean
    begin
        exit(AOAIPolicyParamsImpl.IsDefaultPolicy());
    end;

    /// <summary>
    /// Gets the AOAI policy as text based on the provided policy parameters or a Custom one.
    /// </summary>
    internal procedure GetAOAIPolicy(): Text
    begin
        exit(AOAIPolicyParamsImpl.GetAOAIPolicy());
    end;
}