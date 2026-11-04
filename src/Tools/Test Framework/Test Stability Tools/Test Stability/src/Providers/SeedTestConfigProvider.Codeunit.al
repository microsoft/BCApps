// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.TestLibraries.Utilities;

codeunit 130485 "Seed Test Config. Provider" implements ITestConfigurationProvider
{
    SingleInstance = true;

    var
        Any: Codeunit Any;
        AnyConfiguration: Codeunit "Any Configuration";
        LibraryRandom: Codeunit "Library - Random";
        SeedIsActive: Boolean;

    procedure Initialize(TestConfiguration: Record "Test Configuration")
    begin
        Reset();
        if TestConfiguration."Use Random Seed" then begin
            SeedIsActive := true;
            AnyConfiguration.SetSeed(TestConfiguration."Random Seed");
            ApplyBeforeTestMethodRun();
        end;
    end;

    procedure ApplyBeforeTestMethodRun()
    begin
        if SeedIsActive and AnyConfiguration.IsSet() then begin
            Any.SetSeed(AnyConfiguration.GetSeed());
            LibraryRandom.SetSeed(AnyConfiguration.GetSeed());
        end;
    end;

    procedure Reset()
    begin
        if not SeedIsActive then
            exit;

        AnyConfiguration.ClearSeed();
        Any.SetSeed(1);
        LibraryRandom.SetSeed(1);
        SeedIsActive := false;
    end;
}
