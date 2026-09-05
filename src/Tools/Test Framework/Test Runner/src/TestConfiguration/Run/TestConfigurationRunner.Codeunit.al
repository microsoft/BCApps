// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Applies the active configuration while the base suite runs. For each enabled line of the active
/// configuration the matching provider is asked to contribute per method behavior (for example the
/// WorkDate shift). All work is a no-op unless a configuration is active, so regular test runs are
/// unaffected. The outcome of every test method is captured by the orchestrator after each run.
/// </summary>
codeunit 130474 "Test Configuration Runner"
{
    SingleInstance = true;
    Access = Internal;

    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; FunctionName: Text[128])
    var
        TestConfigurationLine: Record "Test Configuration Line";
        Provider: Interface "ITest Configuration Provider";
    begin
        if not TestConfigurationContext.IsActive() then
            exit;
        if CurrentTestMethodLine."Test Suite" <> TestConfigurationContext.BaseSuite() then
            exit;
        if not TestSuiteMgt.IsTestMethodLine(FunctionName) then
            exit;

        TestConfigurationLine.SetRange("Configuration Code", TestConfigurationContext.ConfigCode());
        TestConfigurationLine.SetRange("Enabled", true);
        if TestConfigurationLine.FindSet() then
            repeat
                Provider := TestConfigurationLine."Provider";
                Provider.OnBeforeTestMethodRun(CurrentTestMethodLine, TestConfigurationLine.GetSettings(), TestConfigurationContext);
            until TestConfigurationLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterTestMethodRun', '', false, false)]
    local procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; FunctionName: Text[128]; IsSuccess: Boolean)
    var
        TestConfigurationLine: Record "Test Configuration Line";
        Provider: Interface "ITest Configuration Provider";
    begin
        if not TestConfigurationContext.IsActive() then
            exit;
        if CurrentTestMethodLine."Test Suite" <> TestConfigurationContext.BaseSuite() then
            exit;
        if not TestSuiteMgt.IsTestMethodLine(FunctionName) then
            exit;

        TestConfigurationLine.SetRange("Configuration Code", TestConfigurationContext.ConfigCode());
        TestConfigurationLine.SetRange("Enabled", true);
        if TestConfigurationLine.FindSet() then
            repeat
                Provider := TestConfigurationLine."Provider";
                Provider.OnAfterTestMethodRun(CurrentTestMethodLine, IsSuccess, TestConfigurationLine.GetSettings(), TestConfigurationContext);
            until TestConfigurationLine.Next() = 0;
    end;
}
