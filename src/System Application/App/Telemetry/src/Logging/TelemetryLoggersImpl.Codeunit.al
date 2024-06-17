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
        CurrentPublisher: Text;
        CurrentTelemetryScope: TelemetryScope;
        NoPublisherErr: Label 'An app from publisher %1 is sending telemetry, but there is no registered telemetry logger for this publisher.', Locked = true;
        RichTelemetryUsedTxt: Label 'A 3rd party app from publisher %1 is using rich telemetry.', Locked = true;
        TelemetryLibraryCategoryTxt: Label 'TelemetryLibrary', Locked = true;
        FirstPartyPublisherTxt: Label 'Microsoft', Locked = true;

    procedure Register(TelemetryLogger: Interface "Telemetry Logger"; Publisher: Text)
    begin
        // Only currentPublisher's logger needs to be saved for ExtensionPublisher scope.
        // TODO: This might need to be changed if we decide to add one more enum value for TelemetryScope.
        if (CurrentTelemetryScope = TelemetryScope::ExtensionPublisher) and (Publisher <> CurrentPublisher) then
            exit;

        if not RegisteredPublishers.Contains(Publisher) then begin
            RegisteredTelemetryLoggers.Add(TelemetryLogger);
            RegisteredPublishers.Add(Publisher);
        end;
    end;

    internal procedure GetTelemetryLoggerFromCurrentPublisher(var TelemetryLogger: Interface "Telemetry Logger"): Boolean
    var
        IsLoggerFromCurrentPublisherFound: Boolean;
    begin
        IsLoggerFromCurrentPublisherFound := RegisteredPublishers.Contains(CurrentPublisher);

        if IsLoggerFromCurrentPublisherFound then begin
            TelemetryLogger := RegisteredTelemetryLoggers.Get(RegisteredPublishers.IndexOf(CurrentPublisher));
            if CurrentPublisher <> FirstPartyPublisherTxt then
                Session.LogMessage('0000HIW', StrSubstNo(RichTelemetryUsedTxt, CurrentPublisher), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryLibraryCategoryTxt);
        end else
            Session.LogMessage('0000G7K', StrSubstNo(NoPublisherErr, CurrentPublisher), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryLibraryCategoryTxt);

        exit(IsLoggerFromCurrentPublisherFound);
    end;

    internal procedure GetRelevantTelemetryLoggers(CallstackModuleInfos: List of [ModuleInfo]) RelevantTelemetryLoggers: List of [Interface "Telemetry Logger"]
    var
        ModuleInfo: ModuleInfo;
    begin
        foreach ModuleInfo in CallstackModuleInfos do
            if RegisteredPublishers.Contains(ModuleInfo.Publisher) and (ModuleInfo.Publisher <> CurrentPublisher) then
                RelevantTelemetryLoggers.Add(RegisteredTelemetryLoggers.Get(RegisteredPublishers.IndexOf(ModuleInfo.Publisher)));
    end;

    internal procedure SetCurrentPublisher(Publisher: Text)
    begin
        CurrentPublisher := Publisher;
    end;

    internal procedure SetCurrentTelemetryScope(TelemetryScope: TelemetryScope)
    begin
        CurrentTelemetryScope := TelemetryScope;
    end;
}