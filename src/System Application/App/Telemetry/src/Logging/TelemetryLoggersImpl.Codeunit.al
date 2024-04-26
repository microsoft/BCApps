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
        TelemetryLoggerFromCurrentPublisher: Interface "Telemetry Logger";
        RegisteredTelemetryLoggers: List of [Interface "Telemetry Logger"];
        RegisteredPublishers: List of [Text];
        CurrentPublisher: Text;
        IsLoggerFromCurrentPublisherFound: Boolean;
        MultipleTelemetryLoggersFoundErr: Label 'More than one telemetry logger has been registered for publisher %1.', Locked = true;
        NoPublisherErr: Label 'An app from publisher %1 is sending telemetry, but there is no registered telemetry logger for this publisher.', Locked = true;
        RichTelemetryUsedTxt: Label 'A 3rd party app from publisher %1 is using rich telemetry.', Locked = true;
        TelemetryLibraryCategoryTxt: Label 'TelemetryLibrary', Locked = true;
        FirstPartyPublisherTxt: Label 'Microsoft', Locked = true;

    procedure Register(TelemetryLogger: Interface "Telemetry Logger"; Publisher: Text)
    begin
        if RegisteredPublishers.Contains(Publisher) then
            // Note: this tag won't be available for ISVs as far as I understand
            Session.LogMessage('0000G7J', StrSubstNo(MultipleTelemetryLoggersFoundErr, Publisher), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryLibraryCategoryTxt)
        else begin
            RegisteredTelemetryLoggers.Add(TelemetryLogger);
            RegisteredPublishers.Add(Publisher);
        end;

        if Publisher = CurrentPublisher then
            if not IsLoggerFromCurrentPublisherFound then begin
                TelemetryLoggerFromCurrentPublisher := TelemetryLogger;
                IsLoggerFromCurrentPublisherFound := true;
            end;
    end;

    internal procedure GetTelemetryLoggerFromCurrentPublisher(var TelemetryLogger: Interface "Telemetry Logger"): Boolean
    begin
        if IsLoggerFromCurrentPublisherFound then begin
            TelemetryLogger := TelemetryLoggerFromCurrentPublisher;
            if CurrentPublisher <> FirstPartyPublisherTxt then
                Session.LogMessage('0000HIW', StrSubstNo(RichTelemetryUsedTxt, CurrentPublisher), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryLibraryCategoryTxt);
        end else
            Session.LogMessage('0000G7K', StrSubstNo(NoPublisherErr, CurrentPublisher), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryLibraryCategoryTxt);

        exit(IsLoggerFromCurrentPublisherFound);
    end;

    internal procedure GetRegisteredTelemetryLoggers(): List of [Interface "Telemetry Logger"]
    begin
        if CurrentPublisher <> FirstPartyPublisherTxt then
            Session.LogMessage('0000HIW', StrSubstNo(RichTelemetryUsedTxt, CurrentPublisher), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryLibraryCategoryTxt);

        exit(RegisteredTelemetryLoggers);
    end;

    internal procedure GetFirstPartyTelemetryLogger(var TelemetryLogger: Interface "Telemetry Logger"): Boolean
    begin
        if RegisteredPublishers.Contains(FirstPartyPublisherTxt) then begin
            TelemetryLogger := RegisteredTelemetryLoggers.Get(RegisteredPublishers.IndexOf(FirstPartyPublisherTxt));
            exit(true);
        end;

        exit(false);
    end;

    internal procedure SetCurrentPublisher(Publisher: Text)
    begin
        CurrentPublisher := Publisher;
    end;
}