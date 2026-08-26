// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Provider that runs the test methods within each codeunit in reverse order. The order is realized
/// when the generated suite is cloned, so no runner change is needed. This surfaces tests that depend
/// on the order methods run in within a codeunit. No settings.
/// </summary>
codeunit 130479 "Reverse Meth. Test Cfg. Prov." implements "ITest Configuration Provider"
{
    var
        DescriptionTxt: Label 'Runs the test methods in reverse order.';

    procedure GetDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

#pragma warning disable AA0150
    procedure Prepare(Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
        TestConfigurationContext.SetReverseMethods(true);
    end;

    procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
    end;

    procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; IsSuccess: Boolean; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
    end;
#pragma warning restore AA0150
}
