// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Provider that runs the suite in reverse order. The order is realized by handing the suite lines to
/// the test runner from the last to the first, so no runner change and no extra suite is needed. The
/// runner honors that for the codeunit sequence, so this reverses the order the test codeunits run in
/// and surfaces tests that depend on that order. The run is not isolated: all tests still run and share
/// state, only the order changes. No settings.
/// </summary>
codeunit 130478 "Reverse Order Test Cfg. Prov." implements "ITest Configuration Provider"
{
    var
        DescriptionTxt: Label 'Runs the suite in reverse order.';

    procedure GetDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

#pragma warning disable AA0150
    procedure Prepare(Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
        TestConfigurationContext.SetReverseOrder(true);
    end;

    procedure Validate(Settings: JsonObject)
    begin
    end;

    procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
    end;

    procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; IsSuccess: Boolean; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
    end;
#pragma warning restore AA0150
}
