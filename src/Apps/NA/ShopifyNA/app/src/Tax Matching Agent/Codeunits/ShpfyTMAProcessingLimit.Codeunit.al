// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Azure.KeyVault;

codeunit 30479 "Shpfy TMA Processing Limit"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        ProcessingLimitSecretNameTok: Label 'ShopifyTaxMatchingProcessingLimit', Locked = true;
        ProcessingLimitUnavailableMsg: Label 'Shopify Tax Matching processing limit configuration unavailable; matching skipped.', Locked = true;
        ProcessingLimitReachedMsg: Label 'Shopify Tax Matching processing limit reached; matching skipped.', Locked = true;
        MaxOrdersPropertyTok: Label 'maxOrders', Locked = true;
        PeriodMinutesPropertyTok: Label 'periodMinutes', Locked = true;

    internal procedure TryAcquire(var OrderHeader: Record "Shpfy Order Header"; var MaxOrders: Integer; var PeriodMinutes: Integer; var ProcessedOrders: Integer): Boolean
    var
        ConfigurationStatus: Text;
        AsOfDateTime: DateTime;
    begin
        if not TryGetConfiguration(MaxOrders, PeriodMinutes, ConfigurationStatus) then begin
            LogConfigurationUnavailable(ConfigurationStatus);
            exit(false);
        end;
        AsOfDateTime := CurrentDateTime();
        if TryAcquireAt(OrderHeader, AsOfDateTime, MaxOrders, PeriodMinutes, ProcessedOrders) then
            exit(true);

        LogLimitReached(MaxOrders, PeriodMinutes, ProcessedOrders);
        exit(false);
    end;

    [NonDebuggable]
    local procedure TryGetConfiguration(var MaxOrders: Integer; var PeriodMinutes: Integer; var ConfigurationStatus: Text): Boolean
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        ConfigurationText: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(ProcessingLimitSecretNameTok, ConfigurationText) then begin
            ConfigurationStatus := 'Missing';
            exit(false);
        end;

        if not TryParseConfiguration(ConfigurationText, MaxOrders, PeriodMinutes) then begin
            ConfigurationStatus := 'Invalid';
            exit(false);
        end;

        ConfigurationStatus := 'Valid';
        exit(true);
    end;

    internal procedure TryParseConfiguration(ConfigurationText: Text; var MaxOrders: Integer; var PeriodMinutes: Integer): Boolean
    var
        Configuration: JsonObject;
    begin
        Clear(MaxOrders);
        Clear(PeriodMinutes);

        if not Configuration.ReadFrom(ConfigurationText) then
            exit(false);
        if not TryGetInteger(Configuration, MaxOrdersPropertyTok, MaxOrders) then
            exit(false);
        if not TryGetInteger(Configuration, PeriodMinutesPropertyTok, PeriodMinutes) then
            exit(false);
        if MaxOrders < 0 then
            exit(false);
        if PeriodMinutes <= 0 then
            exit(false);

        exit(true);
    end;

    internal procedure TryAcquireAt(var OrderHeader: Record "Shpfy Order Header"; AsOfDateTime: DateTime; MaxOrders: Integer; PeriodMinutes: Integer; var ProcessedOrders: Integer): Boolean
    var
        PreviousAttemptedAt: DateTime;
    begin
        if MaxOrders = 0 then begin
            ProcessedOrders := CountProcessedOrders(AsOfDateTime, PeriodMinutes);
            exit(false);
        end;

        PreviousAttemptedAt := OrderHeader."Tax Match Attempted At";
        OrderHeader."Tax Match Attempted At" := AsOfDateTime;
        OrderHeader.Modify();

        ProcessedOrders := CountProcessedOrders(AsOfDateTime, PeriodMinutes);
        if ProcessedOrders <= MaxOrders then
            exit(true);

        OrderHeader."Tax Match Attempted At" := PreviousAttemptedAt;
        OrderHeader.Modify();
        ProcessedOrders := CountProcessedOrders(AsOfDateTime, PeriodMinutes);
        exit(false);
    end;

    local procedure TryGetInteger(Configuration: JsonObject; PropertyName: Text; var Value: Integer): Boolean
    var
        ValueToken: JsonToken;
    begin
        if not Configuration.Get(PropertyName, ValueToken) then
            exit(false);
        if not ValueToken.IsValue() then
            exit(false);
        exit(Evaluate(Value, ValueToken.AsValue().AsText(), 9));
    end;

    local procedure CountProcessedOrders(AsOfDateTime: DateTime; PeriodMinutes: Integer): Integer
    var
        OrderHeader: Record "Shpfy Order Header";
    begin
        OrderHeader.ReadIsolation(IsolationLevel::ReadUncommitted);
        OrderHeader.SetFilter("Tax Match Attempted At", '>%1&<=%2', GetPeriodStart(AsOfDateTime, PeriodMinutes), AsOfDateTime);
        exit(OrderHeader.Count());
    end;

    local procedure GetPeriodStart(AsOfDateTime: DateTime; PeriodMinutes: Integer): DateTime
    var
        PeriodMilliseconds: BigInteger;
    begin
        PeriodMilliseconds := PeriodMinutes;
        PeriodMilliseconds *= 60000;
        exit(AsOfDateTime - PeriodMilliseconds);
    end;

    local procedure LogConfigurationUnavailable(ConfigurationStatus: Text)
    var
        TMARegister: Codeunit "Shpfy TMA Register";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('Category', TMARegister.FeatureName());
        CustomDimensions.Add('ConfigurationStatus', ConfigurationStatus);
        Session.LogMessage('0000UNW', ProcessingLimitUnavailableMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    local procedure LogLimitReached(MaxOrders: Integer; PeriodMinutes: Integer; ProcessedOrders: Integer)
    var
        TMARegister: Codeunit "Shpfy TMA Register";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('Category', TMARegister.FeatureName());
        CustomDimensions.Add('MaxOrders', Format(MaxOrders, 0, 9));
        CustomDimensions.Add('PeriodMinutes', Format(PeriodMinutes, 0, 9));
        CustomDimensions.Add('ProcessedOrders', Format(ProcessedOrders, 0, 9));
        Session.LogMessage('0000UNX', ProcessingLimitReachedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;
}
