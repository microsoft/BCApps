// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Provides an interface for interacting with Tenant No. Series.
/// These No. Series are cross-company and used for cross-company functionality
/// For per-company functionality, see No. Series.
/// </summary>
codeunit 283 "Cross-Company No. Series"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Creates a new cross-company No. Series
    /// </summary>
    /// <param name="NoSeriesCode">The new No. Series code.</param>
    /// <param name="NoSeriesDescription">The new No. Series description.</param>
    /// <param name="LastUsedNo">The last used number from the No. Series. The first number retrieved will be this number increased by one.</param>
    procedure CreateNoSeries(NoSeriesCode: Code[10]; NoSeriesDescription: Text[50]; LastUsedNo: Code[10])
    var
        CrossCompanyNoSeriesImpl: Codeunit "Cross-Company No. Series Impl.";
    begin
        CrossCompanyNoSeriesImpl.CreateNoSeries(NoSeriesCode, NoSeriesDescription, LastUsedNo);
    end;

    /// <summary>
    /// Gets the next available number for the given cross-company No. Series
    /// </summary>
    /// <param name="NoSeriesTenant">The No. Series to get the next number from.</param>
    /// <returns>The next number.</returns>
    procedure GetNextNo(NoSeriesTenant: Record "No. Series Tenant"): Code[20]
    var
        CrossCompanyNoSeriesImpl: Codeunit "Cross-Company No. Series Impl.";
    begin
        exit(CrossCompanyNoSeriesImpl.GetNextNo(NoSeriesTenant));
    end;

    /// <summary>
    /// Gets the next available number for the given cross-company No. Series
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series Tenant to use.</param>
    /// <returns>The next number.</returns>
    procedure GetNextNo(NoSeriesCode: Code[10]): Code[20]
    var
        CrossCompanyNoSeriesImpl: Codeunit "Cross-Company No. Series Impl.";
    begin
        exit(CrossCompanyNoSeriesImpl.GetNextNo(NoSeriesCode));
    end;

    /// <summary>
    /// Checks if the given cross-company No. Series exists
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series Tenant to use.</param>
    /// <returns>Whether the No. Series exist.</returns>
    procedure Exists(NoSeriesCode: Code[10]): Boolean
    var
        CrossCompanyNoSeriesImpl: Codeunit "Cross-Company No. Series Impl.";
    begin
        exit(CrossCompanyNoSeriesImpl.Exist(NoSeriesCode));
    end;
}
