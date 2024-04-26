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
    begin
        AddCommonCustomDimensions(CommonCustomDimensions, CallerModuleInfo);
        LogMessageInternal(EventId, Message, Verbosity, DataClassification, TelemetryScope, CommonCustomDimensions, CallerCustomDimensions, CallerModuleInfo.Publisher);
    end;

    procedure LogMessageInternal(EventId: Text; Message: Text; Verbosity: Verbosity; DataClassification: DataClassification; TelemetryScope: TelemetryScope; CustomDimensions: Dictionary of [Text, Text]; CallerCustomDimensions: Dictionary of [Text, Text]; Publisher: Text)
    var
        TelemetryLoggers: Codeunit "Telemetry Loggers";
        TelemetryLogger, MicrosoftTelemetryLogger : Interface "Telemetry Logger";
        RegisteredTelemetryLoggers: List of [Interface "Telemetry Logger"];
    begin
        AddCustomDimensionsFromSubscribers(CustomDimensions, Publisher);
        AddCustomDimensionsSafely(CustomDimensions, CallerCustomDimensions);

        TelemetryLoggers.SetCurrentPublisher(Publisher);
        TelemetryLoggers.OnRegisterTelemetryLogger();

        if TelemetryScope = TelemetryScope::ExtensionPublisher then begin
            // When Scope is ExtensionPublisher, only the current publisher gets a copy of Telemetry.
            if TelemetryLoggers.GetTelemetryLoggerFromCurrentPublisher(TelemetryLogger) then
                TelemetryLogger.LogMessage(EventId, Message, Verbosity, DataClassification, TelemetryScope::ExtensionPublisher, CustomDimensions);
        end else begin
            // When Scope is All, all publishers get a copy of Telemetry (should be 3rd-party).
            RegisteredTelemetryLoggers := TelemetryLoggers.GetRegisteredTelemetryLoggers();
            foreach TelemetryLogger in RegisteredTelemetryLoggers do
                // we set the scope to ExtensionPublisher for 3rd-party loggers to avoid multiple logging into environment telemetry.
                // todo: need to filter out first-party loggers from RegisteredTelemetryLoggers
                TelemetryLogger.LogMessage(EventId, Message, Verbosity, DataClassification, TelemetryScope::ExtensionPublisher, CustomDimensions);

            if TelemetryLoggers.GetFirstPartyTelemetryLogger(MicrosoftTelemetryLogger) then
                // Then we use first-party logger to log telemetry to All only once.
                MicrosoftTelemetryLogger.LogMessage(EventId, Message, Verbosity, DataClassification, TelemetryScope::All, CustomDimensions);
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

