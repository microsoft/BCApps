// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Utilities;

/// <summary>
/// Passive, single instance store that carries the pseudo-random seed a test run should use.
/// It does NOT change how "Any" or "Library - Random" work: it only holds a value. The test
/// runner writes the seed here before a run, and the code that already seeds the random libraries
/// (for example "Reset State Before Test Run", which calls the existing SetSeed methods) reads it.
/// This lets the test tooling vary randomness for tests that rely on the default seed, while tests
/// that explicitly call SetSeed keep their own seed because that call runs after the reset.
/// This codeunit lives in the "Any" app because it is the only app both "Any" and "Library - Random"
/// can reference.
/// </summary>
codeunit 130501 "Configured Random Seed"
{
    SingleInstance = true;

    var
        SeedValue: Integer;
        SeedIsSet: Boolean;

    /// <summary>
    /// Stores the seed that the random libraries should use for the current run.
    /// </summary>
    /// <param name="NewSeed">The seed value.</param>
    procedure SetSeed(NewSeed: Integer)
    begin
        SeedValue := NewSeed;
        SeedIsSet := true;
    end;

    /// <summary>
    /// Clears the stored seed so the random libraries fall back to their normal behavior.
    /// </summary>
    procedure ClearSeed()
    begin
        SeedIsSet := false;
        SeedValue := 0;
    end;

    /// <summary>
    /// Returns whether a seed has been stored for the current run.
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
