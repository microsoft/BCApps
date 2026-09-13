// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Provider that runs each test method in isolation (one by one) by turning on the stability run
/// behavior of the base suite for the duration of the configuration. Each method runs on its own so
/// its setup runs again for that method only. This surfaces tests that only pass because of state
/// left behind by earlier tests. No settings.
/// </summary>
codeunit 130477 "One By One Test Config. Prov." implements "ITest Configuration Provider"
{
    var
        DescriptionTxt: Label 'Runs each test method in isolation.';

    procedure GetDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

#pragma warning disable AA0150
    procedure Prepare(Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
        TestConfigurationContext.SetOneByOne(true);
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
