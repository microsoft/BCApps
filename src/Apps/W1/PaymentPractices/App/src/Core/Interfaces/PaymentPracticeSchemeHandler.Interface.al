// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

interface PaymentPracticeSchemeHandler
{
    /// <summary>
    /// Validates the Payment Practice Header before data generation.
    /// </summary>
    /// <param name="PaymentPracticeHeader">The header to validate.</param>
    procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header")

    /// <summary>
    /// Enriches or filters a Payment Practice Data row before insertion.
    /// Returns true to include the row, false to skip it.
    /// </summary>
    /// <param name="PaymentPracticeData">The data row to enrich/filter.</param>
    /// <returns>True to include the row, false to skip.</returns>
    procedure UpdatePaymentPracData(var PaymentPracticeData: Record "Payment Practice Data"): Boolean

    /// <summary>
    /// Calculates scheme-specific header totals after standard totals are generated.
    /// </summary>
    /// <param name="PaymentPracticeHeader">The header to update with totals.</param>
    /// <param name="PaymentPracticeData">The data to aggregate from.</param>
    procedure CalculateHeaderTotals(var PaymentPracticeHeader: Record "Payment Practice Header"; var PaymentPracticeData: Record "Payment Practice Data")

    /// <summary>
    /// Calculates scheme-specific line totals for the currently visible slice of data.
    /// The caller is responsible for applying any filters (period, company size, etc.) on
    /// PaymentPracticeData before invoking this method, and for restoring them afterwards.
    /// </summary>
    /// <param name="PaymentPracticeLine">The line to update with totals.</param>
    /// <param name="PaymentPracticeData">The data to aggregate from. Filters set by the caller define the slice.</param>
    procedure CalculateLineTotals(var PaymentPracticeLine: Record "Payment Practice Line"; var PaymentPracticeData: Record "Payment Practice Data")
}
