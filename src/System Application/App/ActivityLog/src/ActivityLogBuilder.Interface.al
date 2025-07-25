// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Log;

// <summary>
// Interface for the Activity Log Builder codeunit.
// This interface defines methods to build and log activity entries for a specific table and field.
// Currently first party applications only to allow for future API changes.
// </summary>
interface "Activity Log Builder"
{
    Scope = OnPrem;

    /// <summary>
    /// Initializes the activity log builder for a specific table and field.
    /// </summary>
    procedure Init(TableNo: Integer; FieldNo: Integer; RecSystemId: Guid): Codeunit "Activity Log Builder";

    /// <summary>
    /// Sets the explanation for the activity log entry.
    /// </summary>
    procedure SetExplanation(Explanation: Text): Codeunit "Activity Log Builder";

    /// <summary>
    /// Sets the type of the activity log entry.
    /// Allowed values are "AI" for AI-related activities and "AL" for general activities
    /// </summary>
    procedure SetType(Type: Enum "Activity Log Type"): Codeunit "Activity Log Builder";

    /// <summary>
    /// Sets the reference source for the activity log entry.
    /// The reference source can be a page ID and a record reference, which will be converted to a URL.
    /// </summary>
    procedure SetReferenceSource(PageId: Integer; var Rec: RecordRef): Codeunit "Activity Log Builder";

    /// <summary>
    /// Sets the reference source for the activity log entry.
    /// This can be a URL or any other text that identifies the source of the reference.
    /// </summary>
    procedure SetReferenceSource(ReferenceSource: Text): Codeunit "Activity Log Builder";

    /// <summary>
    /// Sets the reference title for the activity log entry.
    /// </summary>
    procedure SetReferenceTitle(ReferenceTitle: Text): Codeunit "Activity Log Builder";

    /// <summary>
    /// Logs the activity entry that has been built using the methods of this codeunit.
    /// </summary>
    procedure Log();


}