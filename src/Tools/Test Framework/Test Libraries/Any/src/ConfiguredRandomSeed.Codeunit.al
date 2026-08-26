// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Utilities;

/// <summary>
/// Passive, single instance store that carries the stability run state and the pseudo-random seed a
/// test run should use. It does NOT change how "Any" or "Library - Random" work: it only holds state.
/// The test runner turns stability mode on before a run and off afterwards, and sets the seed for the
/// current configuration. The code that already seeds the random libraries before every test method
/// ("Reset State Before Test Run") reads this state and updates the libraries accordingly, so exiting
/// stability mode restores normal behavior on the very next test.
/// This codeunit lives in the "Any" app because it is the only app both "Any" and "Library - Random"
/// can reference.
/// </summary>
codeunit 130501 "Configured Random Seed"
{
    SingleInstance = true;

    var
        SeedValue: Integer;
        SeedIsSet: Boolean;
        StabilityModeActive: Boolean;

    /// <summary>
    /// Enters stability mode. While active, "Reset State Before Test Run" seeds both random libraries
    /// deterministically before every test method (with the configured seed, or 1 when none is set).
    /// </summary>
    procedure EnterStabilityMode()
    begin
        StabilityModeActive := true;
    end;

    /// <summary>
    /// Exits stability mode and clears the stored seed. From the next test method on, the random
    /// libraries are reset to their normal behavior, so a stability run cannot leak into later runs.
    /// </summary>
    procedure ExitStabilityMode()
    begin
        StabilityModeActive := false;
        ClearSeed();
    end;

    /// <summary>
    /// Returns whether stability mode is currently active.
    /// </summary>
    /// <returns>True if stability mode is active.</returns>
    procedure IsStabilityMode(): Boolean
    begin
        exit(StabilityModeActive);
    end;

    /// <summary>
    /// Stores the seed that the random libraries should use for the current configuration.
    /// </summary>
    /// <param name="NewSeed">The seed value.</param>
    procedure SetSeed(NewSeed: Integer)
    begin
        SeedValue := NewSeed;
        SeedIsSet := true;
    end;

    /// <summary>
    /// Clears the stored seed so the current configuration has no explicit seed.
    /// </summary>
    procedure ClearSeed()
    begin
        SeedIsSet := false;
        SeedValue := 0;
    end;

    /// <summary>
    /// Returns whether a seed has been stored for the current configuration.
    /// </summary>
    /// <returns>True if a seed is stored.</returns>
    procedure IsSet(): Boolean
    begin
        exit(SeedIsSet);
    end;

    /// <summary>
    /// Returns the stored seed value.
    /// </summary>
    /// <returns>The seed value.</returns>
    procedure GetSeed(): Integer
    begin
        exit(SeedValue);
    end;
}
