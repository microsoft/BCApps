// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130474 "Test Configuration Runner"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Initialize(SuiteName: Code[10])
    var
        TestConfiguration: Record "Test Configuration";
        TestConfigurationContext: Codeunit "Test Configuration Context";
        ProviderType: Enum "Test Configuration Provider";
        Provider: Interface "ITest Configuration Provider";
        ProviderOrdinal: Integer;
    begin
        Reset();
        TestConfigurationContext.Initialize(SuiteName);
        TestConfigurationContext.GetConfiguration(TestConfiguration);
        foreach ProviderOrdinal in ProviderType.Ordinals() do begin
            Provider := Enum::"Test Configuration Provider".FromInteger(ProviderOrdinal);
            Provider.Initialize(TestConfiguration);
        end;
    end;

    procedure Reset()
    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
        ProviderType: Enum "Test Configuration Provider";
        Provider: Interface "ITest Configuration Provider";
        ProviderOrdinal: Integer;
    begin
        foreach ProviderOrdinal in ProviderType.Ordinals() do begin
            Provider := Enum::"Test Configuration Provider".FromInteger(ProviderOrdinal);
            Provider.Reset();
        end;
        TestConfigurationContext.Reset();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line")
    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
        ProviderType: Enum "Test Configuration Provider";
        Provider: Interface "ITest Configuration Provider";
        ProviderOrdinal: Integer;
    begin
        if not TestConfigurationContext.IsCurrentSuite(CurrentTestMethodLine."Test Suite") then
            exit;
        foreach ProviderOrdinal in ProviderType.Ordinals() do begin
            Provider := Enum::"Test Configuration Provider".FromInteger(ProviderOrdinal);
            Provider.OnBeforeTestMethodRun();
        end;
    end;
}
