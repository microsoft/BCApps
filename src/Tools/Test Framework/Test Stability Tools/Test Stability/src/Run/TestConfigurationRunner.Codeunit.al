// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.Testability;
using System.TestTools.TestRunner;

codeunit 130484 "Test Configuration Runner" implements ITestHandler
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ApplyConfigurationErr: Label 'The stability configuration could not be applied: %1', Comment = '%1 = Provider error.';
        ResetConfigurationErr: Label '%1 The stability configuration could not be reset: %2', Comment = '%1 = Application error, %2 = Cleanup error.';

    procedure Initialize(SuiteName: Code[10])
    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
    begin
        Reset();
        TestConfigurationContext.Initialize(SuiteName);
    end;

    procedure Reset()
    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
    begin
        ResetProviders();
        TestConfigurationContext.Reset();
    end;

    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext)
    begin
        ApplyConfiguration(Context);
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    begin
        ApplyConfiguration(Context);
    end;

    local procedure ResetProviders()
    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
        ProviderType: Enum "Test Configuration Provider";
        Provider: Interface ITestConfigurationProvider;
        ProviderOrdinal: Integer;
    begin
        if not TestConfigurationContext.HasActiveCodeunit() then
            exit;

        foreach ProviderOrdinal in ProviderType.Ordinals() do begin
            Provider := Enum::"Test Configuration Provider".FromInteger(ProviderOrdinal);
            Provider.Reset();
        end;
        TestConfigurationContext.EndCodeunit();
    end;

    local procedure ApplyConfiguration(Context: TestHandlerContext)
    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
    begin
        if not TestConfigurationContext.IsCurrentCodeunit(Context.CodeunitId) then
            exit;

        // The platform logs handler exceptions without failing the test. Report them at the runner boundary.
        if TestConfigurationContext.GetHandlerError() = '' then
            if not TryApplyProviders() then
                TestConfigurationContext.SetHandlerError(StrSubstNo(ApplyConfigurationErr, GetLastErrorText()));

        if TestConfigurationContext.GetHandlerError() <> '' then
            Context.Skip(TestConfigurationContext.GetHandlerError());
    end;

    [TryFunction]
    local procedure TryApplyProviders()
    var
        ProviderType: Enum "Test Configuration Provider";
        Provider: Interface ITestConfigurationProvider;
        ProviderOrdinal: Integer;
    begin
        foreach ProviderOrdinal in ProviderType.Ordinals() do begin
            Provider := Enum::"Test Configuration Provider".FromInteger(ProviderOrdinal);
            Provider.ApplyBeforeTestMethodRun();
        end;
    end;

    [TryFunction]
    local procedure TryResetProviders()
    begin
        ResetProviders();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeRunTestSuite', '', false, false)]
    local procedure InitializeBeforeRunTestSuite(var TestMethodLine: Record "Test Method Line")
    begin
        Initialize(TestMethodLine."Test Suite");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterRunTestSuite', '', false, false)]
    local procedure ResetAfterRunTestSuite()
    begin
        Reset();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeCodeunitRun', '', false, false)]
    local procedure InitializeBeforeCodeunitRun(var TestMethodLine: Record "Test Method Line")
    var
        TestConfiguration: Record "Test Configuration";
        TestConfigurationContext: Codeunit "Test Configuration Context";
        ProviderType: Enum "Test Configuration Provider";
        Provider: Interface ITestConfigurationProvider;
        ProviderOrdinal: Integer;
    begin
        if not TestConfigurationContext.IsCurrentSuite(TestMethodLine."Test Suite") then
            exit;

        ResetProviders();
        // Initialize outside the platform handler so errors abort before the test codeunit starts.
        TestConfigurationContext.BeginCodeunit(TestMethodLine."Test Codeunit");
        TestConfigurationContext.GetConfiguration(TestConfiguration);
        foreach ProviderOrdinal in ProviderType.Ordinals() do begin
            Provider := Enum::"Test Configuration Provider".FromInteger(ProviderOrdinal);
            Provider.Initialize(TestConfiguration);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterCodeunitRun', '', false, false)]
    local procedure ResetAfterCodeunitRun(var TestMethodLine: Record "Test Method Line")
    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
        HandlerError: Text;
    begin
        if not TestConfigurationContext.IsCurrentSuite(TestMethodLine."Test Suite") then
            exit;

        HandlerError := TestConfigurationContext.GetHandlerError();
        if HandlerError = '' then begin
            ResetProviders();
            exit;
        end;

        if not TryResetProviders() then
            Error(ResetConfigurationErr, HandlerError, GetLastErrorText());
        Error(HandlerError);
    end;
}
