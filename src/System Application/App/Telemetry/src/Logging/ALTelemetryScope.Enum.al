// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Telemetry;

enum 8704 "AL Telemetry Scope"
{
    Access = Internal;

    value(0; ExtensionPublisher)
    {
        Caption = 'Extension Publisher';
        // map to TelemetryScope::ExtensionPublisher
    }
    value(1; Environment)
    {
        Caption = 'Environment';
        // map to TelemetryScope::All
    }
    value(2; All)
    {
        Caption = 'All';
        // Telemetry to 1. Extension Publisher, 2. Environment and 3. ISVs on the callstack
    }
}