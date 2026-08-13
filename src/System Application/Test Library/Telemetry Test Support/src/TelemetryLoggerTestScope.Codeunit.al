// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Telemetry;

using System.Telemetry;

codeunit 139487 "Telemetry Logger Test Scope"
{
    procedure RegisterFirstPartyLogger(var TelemetryLoggers: Codeunit "Telemetry Loggers"; TelemetryLogger: Interface "Telemetry Logger")
    begin
        TelemetryLoggers.ReplaceLoggerForTesting(TelemetryLogger, 'Microsoft');
    end;
}
