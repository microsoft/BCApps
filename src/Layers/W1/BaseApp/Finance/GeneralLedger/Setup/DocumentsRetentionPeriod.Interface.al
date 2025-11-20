// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

interface "Documents - Retention Period"
{
    ///
    /// The following methods are to verify whether posted document can be deleted from country law perspective.
    ///

    /// <summary>
    /// Returns the date - Documents with a Posting Date after this date cannot be deleted.
    /// </summary>
    /// <returns>Law enforced date after which is not possible to delete posted documents.</returns>
    procedure GetDeletionBlockedAfterDate(): Date

    /// <summary>
    /// Returns the date - Documents with a Posting Date before this date cannot be deleted.
    /// </summary>
    /// <returns>Law enforced date which prevents deletion of documents posted prior to that date.</returns>
    procedure GetDeletionBlockedBeforeDate(): Date

    /// <summary>
    /// Returns whether document deletion is allowed by law condiering the Posting Date.
    /// </summary>
    /// <param name="PostingDate">Posting Date of the document</param>
    /// <returns>True if Posting Date is out of date range defined by law.</returns>
    procedure IsDocumentDeletionAllowedByLaw(PostingDate: Date): Boolean

    /// <summary>
    /// Use it to run check on posted documents and block deletion if needed.
    /// </summary>
    /// <param name="PostingDate">Posting Date of the document</param>
    procedure CheckDocumentDeletionAllowedByLaw(PostingDate: Date)
}