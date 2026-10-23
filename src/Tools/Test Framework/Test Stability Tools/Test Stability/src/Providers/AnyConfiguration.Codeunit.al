// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.TestLibraries.Utilities;

/// <summary>
/// Carries the current suite's optional seed to random-library initialization.
/// Explicit calls to random-library setters do not consult this state.
/// </summary>
codeunit 130487 "Any Configuration"
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Any, 'OnBeforeInitializeSeed', '', false, false)]
    local procedure ApplyConfiguredSeed(var InitialSeed: Integer)
    begin
        if SeedIsSet then
            InitialSeed := SeedValue;
    end;
}
