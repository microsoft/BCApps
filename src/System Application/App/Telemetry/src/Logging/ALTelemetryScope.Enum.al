// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Telemetry;

/// <summary>
/// Represents the emission scope of the telemetry signal.
/// An wrapper in AL to provide the capability to send Telemetries to ISVs.
/// </summary>
enum 8704 "AL Telemetry Scope"
{
    Access = Internal;

    value(0; ExtensionPublisher)
    {
        /// <summary>
        /// Emit telemetry to only extensions publisher. Corresponds to TelemetryScope::ExtensionPublisher.
        /// </summary>
        Caption = 'Extension Publisher';
    }
    value(1; Environment)
    {
        /// <summary>
        /// Emit telemetry to extensions publisher and environment. Corresponds to TelemetryScope::All.
        /// </summary>
        Caption = 'Environment';
    }
    value(2; All)
    {
        /// <summary>
        /// Emit telemetry to extensions publisher, environment and ISVs on the callstack.
        /// </summary>
        Caption = 'All';
    }
}