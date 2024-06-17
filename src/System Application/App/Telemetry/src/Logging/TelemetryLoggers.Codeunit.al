// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Telemetry;

/// <summary>
/// Provides functionality for registering 3d party telemetry loggers to be used with Telemetry codeunit.
/// </summary>
/// <remarks>This codeunit is only intended to be used from subscribers of <see cref="OnRegisterTelemetryLogger"/> event.</remarks>
codeunit 8708 "Telemetry Loggers"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TelemetryLoggersImpl: Codeunit "Telemetry Loggers Impl.";

    /// <summary>
    /// Registers a telemetry logger from a 3d party extension. Is used in conjunction with <see cref="OnRegisterTelemetryLogger"/>
    /// </summary>
    /// <param name="TelemetryLogger">The codeunit implementing the Telemetry Logger inteface from a 3d party extension.</param>
    procedure Register(TelemetryLogger: Interface "Telemetry Logger")
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        TelemetryLoggersImpl.Register(TelemetryLogger, CallerModuleInfo.Publisher);
    end;

    /// <summary>
    /// Allows 3d party extensions to register their own telemetry loggers to be used with Telemetry codeunit. Is used in conjunction with <see cref="Register"/>.
    /// </summary>
    /// <example>
    /// [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Loggers", 'OnRegisterTelemetryLogger', '', true, true)]
    /// local procedure OnRegisterTelemetryLogger(var Sender: Codeunit "Telemetry Loggers")
    /// var
    ///     MyTelemetryLogger: Codeunit "My Telemetry Logger"; // this codeunit must implement the Telemetry Logger interface
    /// begin
    ///     Sender.Register(MyTelemetryLogger);
    /// end;
    /// </example>
    [IntegrationEvent(true, false)]
    internal procedure OnRegisterTelemetryLogger()
    begin
    end;

    /// <summary>
    /// Get the telemetry logger from the current publisher. If there are multiple telemetry loggers registered for the current publisher, a warning is logged.
    /// </summary>
    internal procedure GetTelemetryLoggerFromCurrentPublisher(var TelemetryLogger: Interface "Telemetry Logger"): Boolean
    begin
        exit(TelemetryLoggersImpl.GetTelemetryLoggerFromCurrentPublisher(TelemetryLogger));
    end;

    /// <summary>
    /// Gets the relevant telemetry loggers based on the callstack module infos, doesn't include the current publisher's logger.
    /// </summary>
    /// <param name="CallstackModuleInfos">A unique set of ModuleInfos on the current callstack</param>
    internal procedure GetRelevantTelemetryLoggers(CallstackModuleInfos: List of [ModuleInfo]): List of [Interface "Telemetry Logger"]
    begin
        exit(TelemetryLoggersImpl.GetRelevantTelemetryLoggers(CallstackModuleInfos));
    end;

    internal procedure SetCurrentPublisher(Publisher: Text)
    begin
        TelemetryLoggersImpl.SetCurrentPublisher(Publisher);
    end;

    internal procedure SetCurrentTelemetryScope(TelemetryScope: TelemetryScope)
    begin
        TelemetryLoggersImpl.SetCurrentTelemetryScope(TelemetryScope);
    end;

    internal procedure Register(TelemetryLogger: Interface "Telemetry Logger"; Publisher: Text)
    begin
        TelemetryLoggersImpl.Register(TelemetryLogger, Publisher);
    end;
}

