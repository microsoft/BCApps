// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Telemetry;

using System.Globalization;
using System.Environment.Configuration;
using System.Environment;

codeunit 8712 "Telemetry Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions = tabledata "User Personalization" = r,
                  tabledata Company = r;

    var
        CustomDimensionsNameClashErr: Label 'Multiple custom dimensions with the same dimension name provided.', Locked = true;
        FirstPartyPublisherTxt: Label 'Microsoft', Locked = true;

    procedure LogMessage(EventId: Text; Message: Text; Verbosity: Verbosity; DataClassification: DataClassification; TelemetryScope: TelemetryScope; CallerCustomDimensions: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo)
    var
        CommonCustomDimensions: Dictionary of [Text, Text];
        CallStackPublishers: List of [Text];
    begin
        AddCommonCustomDimensions(CommonCustomDimensions, CallerModuleInfo);

        CallStackPublishers.Add(CallerModuleInfo.Publisher);

        case TelemetryScope of
            TelemetryScope::ExtensionPublisher:
                LogMessageInternal(EventId, Message, Verbosity, DataClassification, Enum::"AL Telemetry Scope"::ExtensionPublisher, CommonCustomDimensions, CallerCustomDimensions, CallerModuleInfo.Publisher, CallStackPublishers);
            TelemetryScope::All:
                LogMessageInternal(EventId, Message, Verbosity, DataClassification, Enum::"AL Telemetry Scope"::Environment, CommonCustomDimensions, CallerCustomDimensions, CallerModuleInfo.Publisher, CallStackPublishers);
        end;
    end;

    procedure LogMessage(EventId: Text; Message: Text; Verbosity: Verbosity; DataClassification: DataClassification; ALTelemetryScope: Enum "AL Telemetry Scope"; CallerCustomDimensions: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo; CallerCallStackModuleInfos: List of [ModuleInfo])
    var
        CommonCustomDimensions: Dictionary of [Text, Text];
        CallStackPublishers: List of [Text];
        Module: ModuleInfo;
    begin
        AddCommonCustomDimensions(CommonCustomDimensions, CallerModuleInfo);

        foreach Module in CallerCallStackModuleInfos do
            if not CallStackPublishers.Contains(Module.Publisher) then
                CallStackPublishers.Add(Module.Publisher);

        LogMessageInternal(EventId, Message, Verbosity, DataClassification, ALTelemetryScope, CommonCustomDimensions, CallerCustomDimensions, CallerModuleInfo.Publisher, CallStackPublishers);
    end;

    procedure LogMessageInternal(EventId: Text; Message: Text; Verbosity: Verbosity; DataClassification: DataClassification; ALTelemetryScope: Enum "AL Telemetry Scope"; CustomDimensions: Dictionary of [Text, Text]; CallerCustomDimensions: Dictionary of [Text, Text]; Publisher: Text; CallStackPublishers: List of [Text])
    var
        TelemetryLoggers: Codeunit "Telemetry Loggers";
        TelemetryLogger: Interface "Telemetry Logger";
        RelevantTelemetryLoggers: List of [Interface "Telemetry Logger"];
    begin
        AddCustomDimensionsFromSubscribers(CustomDimensions, Publisher);
        AddCustomDimensionsSafely(CustomDimensions, CallerCustomDimensions);

        TelemetryLoggers.SetCallStackPublishers(CallStackPublishers);

        TelemetryLoggers.OnRegisterTelemetryLogger();

        case ALTelemetryScope of
            Enum::"AL Telemetry Scope"::ExtensionPublisher:
                if TelemetryLoggers.GetTelemetryLogger(Publisher, TelemetryLogger) then
                    TelemetryLogger.LogMessage(EventId, Message, Verbosity, DataClassification, TelemetryScope::ExtensionPublisher, CustomDimensions);
            Enum::"AL Telemetry Scope"::Environment:
                if TelemetryLoggers.GetTelemetryLogger(Publisher, TelemetryLogger) then
                    TelemetryLogger.LogMessage(EventId, Message, Verbosity, DataClassification, TelemetryScope::All, CustomDimensions);
            Enum::"AL Telemetry Scope"::All:
                begin
                    // Use current publisher's logger to log telemetry to 1. the current publisher and 2. the environment.
                    if TelemetryLoggers.GetTelemetryLogger(Publisher, TelemetryLogger) then
                        TelemetryLogger.LogMessage(EventId, Message, Verbosity, DataClassification, TelemetryScope::All, CustomDimensions);

                    // Loop through all other loggers on the CallerCallStack to log telemetry to 3. registered loggers.
                    RelevantTelemetryLoggers := TelemetryLoggers.GetRelevantTelemetryLoggers(Publisher);
                    foreach TelemetryLogger in RelevantTelemetryLoggers do
                        TelemetryLogger.LogMessage(EventId, Message, Verbosity, DataClassification, TelemetryScope::ExtensionPublisher, CustomDimensions);
                end;
        end;
    end;

    local procedure AddCommonCustomDimensions(CustomDimensions: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo)
    var
        Company: Record Company;
        UserPersonalization: Record "User Personalization";
        Language: Codeunit Language;
        CurrentLanguage: Integer;
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        CustomDimensions.Add('CallerAppName', CallerModuleInfo.Name);
        CustomDimensions.Add('CallerAppVersionMajor', Format(CallerModuleInfo.AppVersion.Major));
        CustomDimensions.Add('CallerAppVersionMinor', Format(CallerModuleInfo.AppVersion.Minor));
        CustomDimensions.Add('ClientType', Format(CurrentClientType()));
        CustomDimensions.Add('Company', CompanyName());

        if Company.ReadPermission() then
            if Company.Get(CompanyName()) then
                CustomDimensions.Add('IsEvaluationCompany', Language.ToDefaultLanguage(Company."Evaluation Company"));

        if UserPersonalization.ReadPermission() then
            if UserPersonalization.Get(UserSecurityId()) then
                if not IsNullGuid(UserPersonalization."App ID") then
                    CustomDimensions.Add('UserRole', UserPersonalization."Profile ID");

        GlobalLanguage(CurrentLanguage);
    end;

    local procedure AddCustomDimensionsFromSubscribers(CustomDimensions: Dictionary of [Text, Text]; Publisher: Text)
    var
        Language: Codeunit Language;
        TelemetryCustomDimensions: Codeunit "Telemetry Custom Dimensions";
        CustomDimensionsFromSubscribers: Dictionary of [Text, Text];
        CurrentLanguage: Integer;
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        TelemetryCustomDimensions.AddAllowedCommonCustomDimensionPublisher(Publisher);
        TelemetryCustomDimensions.AddAllowedCommonCustomDimensionPublisher(FirstPartyPublisherTxt);
        TelemetryCustomDimensions.OnAddCommonCustomDimensions();

        if FirstPartyPublisherTxt <> Publisher then begin
            CustomDimensionsFromSubscribers := TelemetryCustomDimensions.GetAdditionalCommonCustomDimensions(FirstPartyPublisherTxt);
            AddCustomDimensionsSafely(CustomDimensions, CustomDimensionsFromSubscribers);
        end;
        CustomDimensionsFromSubscribers := TelemetryCustomDimensions.GetAdditionalCommonCustomDimensions(Publisher);
        AddCustomDimensionsSafely(CustomDimensions, CustomDimensionsFromSubscribers);

        GlobalLanguage(CurrentLanguage);
    end;

    procedure AddCustomDimensionsSafely(CustomDimensions: Dictionary of [Text, Text]; CustomDimensionsToAdd: Dictionary of [Text, Text])
    var
        CustomDimensionName: Text;
    begin
        foreach CustomDimensionName in CustomDimensionsToAdd.Keys() do
            if not CustomDimensions.ContainsKey(CustomDimensionName) then
                CustomDimensions.Add(CustomDimensionName, CustomDimensionsToAdd.Get(CustomDimensionName))
            else
                Session.LogMessage('0000G7I', CustomDimensionsNameClashErr, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'TelemetryLibrary');
    end;
}

