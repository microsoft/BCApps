// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Default implementation of document retention period provider.
/// Returns permissive defaults that do not block deletion by law.
/// </summary>
codeunit 800 "Default Retention Period Def." implements "Documents - Retention Period"
{
    /// <summary>
    /// Gets the date after which document deletion is blocked by retention policy.
    /// </summary>
    /// <returns>A date value; 0D means no blocking after a specific date</returns>
    procedure GetDeletionBlockedAfterDate(): Date
    begin
        exit(0D);
    end;

    /// <summary>
    /// Gets the date before which document deletion is blocked by retention policy.
    /// </summary>
    /// <returns>A date value; 0D means no blocking before a specific date</returns>
    procedure GetDeletionBlockedBeforeDate(): Date
    begin
        exit(0D);
    end;

    /// <summary>
    /// Checks whether deletion of a document posted on the specified date is allowed by law.
    /// </summary>
    /// <param name="PostingDate">Document posting date</param>
    /// <returns>True if deletion is allowed; false otherwise</returns>
    procedure IsDocumentDeletionAllowedByLaw(PostingDate: Date): Boolean
    begin
        exit(true);
    end;

    /// <summary>
    /// Throws an error if deletion of a document posted on the specified date is not allowed by law.
    /// </summary>
    /// <param name="PostingDate">Document posting date</param>
    procedure CheckDocumentDeletionAllowedByLaw(PostingDate: Date)
    begin
    end;
}
