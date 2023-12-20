// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Specifies the interface for No. Series implementations.
/// </summary>
interface "No. Series - Single"
{
    /// <summary>
    /// Get the next number in the No. Series, without incrementing the number.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <returns>The next number in the series.</returns>
    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]

    /// <summary>
    /// Get the next number in the No. Series.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <param name="HideErrorsAndWarnings">Whether errors should be ignored.</param>
    /// <returns>The next number in the series, if HideErrorsAndWarnings is true and errors occur, a blank code is returned.</returns>
    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]

    /// <summary>
    /// Get the last number used in the No. Series.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <returns>The last number used in the series.</returns>
    procedure GetLastNoUsed(NoSeriesLine: Record "No. Series Line"): Code[20]

    /// <summary>
    /// Specifies whether the implementation may produce gaps in the No. Series.
    /// For some business scenarios it is important that the No. Series does not produce gaps. This procedure is used to verify that does not happen.
    /// </summary>
    /// <returns>Whether it is possible that the implementation will produce gaps.</returns>
    procedure MayProduceGaps(): Boolean
}
