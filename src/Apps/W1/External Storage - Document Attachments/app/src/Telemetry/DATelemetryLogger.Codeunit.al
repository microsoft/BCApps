// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using System.Telemetry;

/// <summary>
/// Adds support for the extension to use the "Telemetry" and "Feature Telemetry" codeunits.
/// </summary>
codeunit 8753 "DA Telemetry Logger" implements "Telemetry Logger"
{
    Access = Internal;

    procedure LogMessage(EventId: Text; Message: Text; Verbosity: Verbosity; DataClassification: DataClassification; TelemetryScope: TelemetryScope; CustomDimensions: Dictionary of [Text, Text])
    begin
        Session.LogMessage(EventId, Message, Verbosity, DataClassification, TelemetryScope, CustomDimensions);
    end;

    // For the functionality to behave as expected, there must be exactly one implementation of the "Telemetry Logger" interface registered per app publisher
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Loggers", 'OnRegisterTelemetryLogger', '', true, true)]
    local procedure OnRegisterTelemetryLogger(var Sender: Codeunit "Telemetry Loggers")
    var
        DATelemetryLogger: Codeunit "DA Telemetry Logger";
    begin
        Sender.Register(DATelemetryLogger);
    end;
}
