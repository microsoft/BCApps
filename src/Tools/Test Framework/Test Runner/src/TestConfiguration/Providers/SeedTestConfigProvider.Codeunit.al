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
        AnyConfiguration: Codeunit "Any Configuration";

    procedure Initialize(TestConfiguration: Record "Test Configuration")
    begin
        Reset();
        if TestConfiguration."Use Random Seed" then begin
            AnyConfiguration.SetSeed(TestConfiguration."Random Seed");
            Any.SetSeed(TestConfiguration."Random Seed");
        end;
    end;

    procedure ApplyBeforeTestMethodRun()
    begin
        if AnyConfiguration.IsSet() then
            Any.SetSeed(AnyConfiguration.GetSeed());
    end;

    procedure Reset()
    begin
        AnyConfiguration.ClearSeed();
        Any.SetSeed(1);
    end;
}
