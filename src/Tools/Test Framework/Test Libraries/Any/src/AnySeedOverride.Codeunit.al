// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Utilities;

/// <summary>
/// Single instance store used by the test stability tools to force a specific pseudo-random seed.
/// When an override is active, both "Any" and "Library - Random" use the override seed even when a
/// test hardcodes its own seed (for example LibraryRandom.SetSeed(1) inside Initialize).
/// This makes it possible to re-run a suite with different random values in order to surface
/// data-dependent (flaky) tests.
/// </summary>
codeunit 130501 "Any Seed Override"
{
    SingleInstance = true;

    var
        OverrideSeed: Integer;
        OverrideActive: Boolean;

    /// <summary>
    /// Activates the seed override. While active, SetSeed calls honor <paramref name="NewSeed"/>.
    /// </summary>
    /// <param name="NewSeed">The seed to force.</param>
    procedure SetOverride(NewSeed: Integer)
    begin
        OverrideSeed := NewSeed;
        OverrideActive := true;
    end;

    /// <summary>
    /// Clears the seed override so that the standard seeding behavior applies again.
    /// </summary>
    procedure ClearOverride()
    begin
        OverrideActive := false;
        OverrideSeed := 0;
    end;

    /// <summary>
    /// Returns whether a seed override is currently active.
    /// </summary>
    /// <returns>True if an override seed should be used.</returns>
    procedure IsActive(): Boolean
    begin
        exit(OverrideActive);
    end;

    /// <summary>
    /// Returns the currently configured override seed.
    /// </summary>
    /// <returns>The override seed value.</returns>
    procedure GetSeed(): Integer
    begin
        exit(OverrideSeed);
    end;
}
