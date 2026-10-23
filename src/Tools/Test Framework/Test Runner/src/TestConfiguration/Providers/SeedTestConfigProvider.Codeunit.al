// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Utilities;

codeunit 130475 "Seed Test Config. Provider" implements ITestConfigurationProvider
{
    var
        Any: Codeunit Any;
        ConfiguredRandomSeed: Codeunit "Configured Random Seed";

    procedure Initialize(TestConfiguration: Record "Test Configuration")
    begin
        Reset();
        if TestConfiguration."Use Random Seed" then begin
            ConfiguredRandomSeed.SetSeed(TestConfiguration."Random Seed");
            Any.SetSeed(TestConfiguration."Random Seed");
        end;
    end;

    procedure ApplyBeforeTestMethodRun()
    begin
        if ConfiguredRandomSeed.IsSet() then
            Any.SetSeed(ConfiguredRandomSeed.GetSeed());
    end;

    procedure Reset()
    begin
        ConfiguredRandomSeed.ClearSeed();
        Any.SetSeed(1);
    end;
}
