// remove

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
    Permissions = tabledata "No. Series Tenant" = rimd;

    /// <summary>
    /// Creates a new cross-company No. Series
    /// </summary>
    /// <param name="NoSeriesCode">The new No. Series code.</param>
    /// <param name="NoSeriesDescription">The new No. Series description.</param>
    /// <param name="LastUsedNo">The last used number from the No. Series. The first number retrieved will be this number increased by one.</param>
    procedure CreateNoSeries(NoSeriesCode: Code[10]; NoSeriesDescription: Text[50]; LastUsedNo: Code[10])
    var
        NoSeriesTenant: Record "No. Series Tenant";
    begin
        NoSeriesTenant.Validate(Code, NoSeriesCode);
        NoSeriesTenant.Validate(Description, NoSeriesDescription);
        NoSeriesTenant.Validate("Last Used number", LastUsedNo);
        NoSeriesTenant.Insert(true);
    end;

    /// <summary>
    /// Gets the next available number for the given cross-company No. Series
    /// </summary>
    /// <param name="NoSeriesTenant">The No. Series to get the next number from.</param>
    /// <returns>The next number.</returns>
    procedure GetNextNo(NoSeriesTenant: Record "No. Series Tenant") NextAvailableCode: Code[20]
    begin
        NextAvailableCode := CopyStr(IncStr(NoSeriesTenant.Code + NoSeriesTenant."Last Used number"), 1, MaxStrLen(NextAvailableCode));
        NoSeriesTenant.Validate("Last Used number", IncStr(NoSeriesTenant."Last Used number"));
        NoSeriesTenant.Modify();
        exit(NextAvailableCode);
    end;
}