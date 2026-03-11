// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Telemetry;

codeunit 8709 "Telemetry Loggers Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        RegisteredTelemetryLoggers: List of [Interface "Telemetry Logger"];
        RegisteredPublishers: List of [Text];
        CallStackPublishers: List of [Text];
        NoPublisherErr: Label 'An app from publisher %1 is sending telemetry, but there is no registered telemetry logger for this publisher.', Locked = true;
        RichTelemetryUsedTxt: Label 'A 3rd party app from publisher %1 is using rich telemetry.', Locked = true;
        TelemetryLibraryCategoryTxt: Label 'TelemetryLibrary', Locked = true;
        FirstPartyPublisherTxt: Label 'Microsoft', Locked = true;

    procedure Register(TelemetryLogger: Interface "Telemetry Logger"; Publisher: Text)
    begin
        if not CallStackPublishers.Contains(Publisher) then
            exit;

        if not RegisteredPublishers.Contains(Publisher) then begin
            RegisteredTelemetryLoggers.Add(TelemetryLogger);
            RegisteredPublishers.Add(Publisher);
        end;
    end;

    internal procedure GetTelemetryLogger(Publisher: Text; var TelemetryLogger: Interface "Telemetry Logger"): Boolean
    var
        IsLoggerFound: Boolean;
    begin
        IsLoggerFound := RegisteredPublishers.Contains(Publisher);

        if IsLoggerFound then begin
            TelemetryLogger := RegisteredTelemetryLoggers.Get(RegisteredPublishers.IndexOf(Publisher));
            if Publisher <> FirstPartyPublisherTxt then
                Session.LogMessage('0000HIW', StrSubstNo(RichTelemetryUsedTxt, Publisher), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryLibraryCategoryTxt);
        end else
            Session.LogMessage('0000G7K', StrSubstNo(NoPublisherErr, Publisher), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryLibraryCategoryTxt);

        exit(IsLoggerFound);
    end;

    internal procedure GetRelevantTelemetryLoggers(ExcludePublisher: Text) RelevantTelemetryLoggers: List of [Interface "Telemetry Logger"]
    var
        Publisher: Text;
    begin
        foreach Publisher in RegisteredPublishers do
            if Publisher <> ExcludePublisher then
                RelevantTelemetryLoggers.Add(RegisteredTelemetryLoggers.Get(RegisteredPublishers.IndexOf(Publisher)));
    end;

    internal procedure SetCallStackPublishers(Publishers: List of [Text])
    begin
        CallStackPublishers := Publishers;
    end;
}