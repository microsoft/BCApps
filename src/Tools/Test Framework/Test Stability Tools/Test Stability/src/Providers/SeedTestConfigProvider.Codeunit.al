// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.TestLibraries.Utilities;
using System.TestTools.TestRunner;

codeunit 130485 "Seed Test Config. Provider" implements ITestConfigurationProvider
{
    var
        Any: Codeunit Any;
        AnyConfiguration: Codeunit "Any Configuration";
        LibraryRandom: Codeunit "Library - Random";

    procedure Initialize(TestConfiguration: Record "Test Configuration")
    begin
        Reset();
        if TestConfiguration."Use Random Seed" then begin
            AnyConfiguration.SetSeed(TestConfiguration."Random Seed");
            Any.SetSeed(TestConfiguration."Random Seed");
            LibraryRandom.SetSeed(TestConfiguration."Random Seed");
        end;
    end;

    procedure ApplyBeforeTestMethodRun()
    begin
        if AnyConfiguration.IsSet() then begin
            Any.SetSeed(AnyConfiguration.GetSeed());
            LibraryRandom.SetSeed(AnyConfiguration.GetSeed());
        end;
    end;

    procedure Reset()
    begin
        AnyConfiguration.ClearSeed();
        Any.SetSeed(1);
        LibraryRandom.SetSeed(1);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALTestRunner Reset Environment", 'OnAfterInitialize', '', false, false)]
    local procedure ApplySeedAfterEnvironmentInitialization()
    begin
        ApplyBeforeTestMethodRun();
    end;
}
