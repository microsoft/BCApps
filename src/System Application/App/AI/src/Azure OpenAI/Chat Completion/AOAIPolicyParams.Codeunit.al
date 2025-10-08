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
    Access = Public;
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
    /// <returns>The current AOAI Policy XPIA Detection.</returns>
    procedure GetXPIADetection(): Enum "AOAI Policy XPIA Detection"
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
    /// <param name="XPIADetection">The AOAI Policy XPIA Detection to set.</param>
    procedure SetXPIADetection(XPIADetection: Enum "AOAI Policy XPIA Detection")
    begin
        AOAIPolicyParamsImpl.SetXPIADetection(XPIADetection);
    end;
}