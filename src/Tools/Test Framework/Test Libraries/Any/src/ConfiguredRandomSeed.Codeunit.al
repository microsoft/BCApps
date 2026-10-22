// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Utilities;

/// <summary>
/// Carries the current suite's optional seed to the legacy random-library reset.
/// Explicit calls to random-library setters do not consult this state.
/// </summary>
codeunit 130501 "Configured Random Seed"
{
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SeedValue: Integer;
        SeedIsSet: Boolean;

    procedure SetSeed(NewSeed: Integer)
    begin
        SeedValue := NewSeed;
        SeedIsSet := true;
    end;

    procedure ClearSeed()
    begin
        Clear(SeedValue);
        SeedIsSet := false;
    end;

    procedure IsSet(): Boolean
    begin
        exit(SeedIsSet);
    end;

    procedure GetSeed(): Integer
    begin
        exit(SeedValue);
    end;
}
