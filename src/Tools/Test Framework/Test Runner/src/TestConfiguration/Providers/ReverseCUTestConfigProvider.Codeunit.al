// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Provider that runs the test codeunits in reverse order. The order is realized by handing the suite
/// lines to the test runner from the last to the first, so no runner change and no extra suite is
/// needed. This surfaces tests that depend on the order codeunits run in. No settings.
/// </summary>
codeunit 130478 "Reverse CU Test Config. Prov." implements "ITest Configuration Provider"
{
    var
        DescriptionTxt: Label 'Runs the test codeunits in reverse order.';

    procedure GetDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

#pragma warning disable AA0150
    procedure Prepare(Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
        TestConfigurationContext.SetReverseCodeunits(true);
    end;

    procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
    end;

    procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; IsSuccess: Boolean; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
    end;
#pragma warning restore AA0150
}
