// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.API.Codeunits;

using Microsoft.Foundation.NoSeries;

/// <summary>
/// API codeunit exposing No. Series operations as non-data-bound (unbound) actions.
/// Wraps codeunits "No. Series" (310) and "No. Series - Batch" (308).
/// </summary>
/// <remarks>
/// TODO(AB#641822): once the platform ships the API codeunit subtype, decorate this codeunit with
/// Subtype = API and the APIPublisher = 'microsoft' / APIGroup = 'codeunits' / APIVersion properties
/// (and expose the procedures as the codeunit's service-enabled actions). Until then this is a plain
/// public codeunit so the wrapper logic can be authored ahead of the platform.
/// </remarks>
codeunit 6007 "No. Series API"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>Gets the next number in the number series, advancing the series.</summary>
    /// <param name="NoSeriesCode">The number series code.</param>
    /// <returns>The next number.</returns>
    procedure GetNextNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.GetNextNo(NoSeriesCode));
    end;

    /// <summary>Gets the next number in the number series for the given usage date, advancing the series.</summary>
    /// <param name="NoSeriesCode">The number series code.</param>
    /// <param name="UsageDate">The date the number is used on.</param>
    /// <returns>The next number.</returns>
    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.GetNextNo(NoSeriesCode, UsageDate));
    end;

    /// <summary>Returns the next number in the series without advancing it.</summary>
    /// <param name="NoSeriesCode">The number series code.</param>
    /// <returns>The next number.</returns>
    procedure PeekNextNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode));
    end;

    /// <summary>Returns the next number in the series for the given usage date without advancing it.</summary>
    /// <param name="NoSeriesCode">The number series code.</param>
    /// <param name="UsageDate">The date the number is used on.</param>
    /// <returns>The next number.</returns>
    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode, UsageDate));
    end;

    /// <summary>Returns the last number used in the series.</summary>
    /// <param name="NoSeriesCode">The number series code.</param>
    /// <returns>The last number used.</returns>
    procedure GetLastNoUsed(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.GetLastNoUsed(NoSeriesCode));
    end;

    /// <summary>Returns whether the number series requires numbers to be entered manually.</summary>
    /// <param name="NoSeriesCode">The number series code.</param>
    /// <returns>True if manual; otherwise false.</returns>
    procedure IsManual(NoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.IsManual(NoSeriesCode));
    end;

    /// <summary>Returns whether the number series assigns numbers automatically.</summary>
    /// <param name="NoSeriesCode">The number series code.</param>
    /// <returns>True if automatic; otherwise false.</returns>
    procedure IsAutomatic(NoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.IsAutomatic(NoSeriesCode));
    end;

    /// <summary>Returns whether the number series enforces date order.</summary>
    /// <param name="NoSeriesCode">The number series code.</param>
    /// <returns>True if the series is in date order; otherwise false.</returns>
    procedure IsNoSeriesInDateOrder(NoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.IsNoSeriesInDateOrder(NoSeriesCode));
    end;

    /// <summary>Simulates getting the next number given the last number used, without persisting state.</summary>
    /// <param name="NoSeriesCode">The number series code.</param>
    /// <param name="UsageDate">The date the number is used on.</param>
    /// <param name="LastNoUsed">The last number used to simulate from.</param>
    /// <returns>The simulated next number.</returns>
    procedure SimulateGetNextNo(NoSeriesCode: Code[20]; UsageDate: Date; LastNoUsed: Code[20]): Code[20]
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
    begin
        exit(NoSeriesBatch.SimulateGetNextNo(NoSeriesCode, UsageDate, LastNoUsed));
    end;
}
