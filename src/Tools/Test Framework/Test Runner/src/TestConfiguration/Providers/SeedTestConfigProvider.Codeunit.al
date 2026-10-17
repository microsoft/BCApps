// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Utilities;

/// <summary>
/// Provider that varies the pseudo-random seed used by the random test libraries. It stores the
/// requested seed in the shared context and in "Configured Random Seed". While stability mode is
/// active, "Any" and "Library - Random" honor that seed from their own SetSeed, so it takes effect
/// even when a test reseeds in its own Initialize. Settings: { "seed": 2 }.
/// </summary>
codeunit 130475 "Seed Test Config. Provider" implements "ITest Configuration Provider"
{
    var
        DescriptionTxt: Label 'Uses a different random seed.';
        InvalidSeedErr: Label 'The seed ''%1'' is not a valid integer.', Comment = '%1 = the configured seed';

    procedure GetDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

    procedure Validate(Settings: JsonObject)
    var
        SeedToken: JsonToken;
        SeedValue: Integer;
    begin
        if not Settings.Get('seed', SeedToken) then
            exit;
        if not SeedToken.IsValue() then
            exit;
        if SeedToken.AsValue().IsNull() then
            exit;
        if not Evaluate(SeedValue, SeedToken.AsValue().AsText()) then
            Error(InvalidSeedErr, SeedToken.AsValue().AsText());
    end;

    procedure Prepare(Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    var
        SeedToken: JsonToken;
        Seed: Integer;
    begin
        Seed := 1;
        if Settings.Get('seed', SeedToken) then
            if SeedToken.IsValue() then
                if not SeedToken.AsValue().IsNull() then
                    Seed := SeedToken.AsValue().AsInteger();
        TestConfigurationContext.SetSeed(Seed);
    end;

#pragma warning disable AA0150
    procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
    end;

    procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; IsSuccess: Boolean; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
    end;
#pragma warning restore AA0150
}
