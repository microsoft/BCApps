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
    /// Gets the AOAI policy enum based on the provided policy parameters.
    /// </summary>
    /// <returns>The corresponding AOAI policy enum value.</returns>
    internal procedure GetAOAIPolicy(): Enum "AOAI Policy"
    begin
        exit(AOAIPolicyParamsImpl.GetAOAIPolicy());
    end;
}