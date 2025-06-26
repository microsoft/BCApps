// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Log;

/// <summary>
/// Codeunit to build and log activity entries for a specific table and field.
/// Currently first party applications only to allow for future API changes. 
/// </summary>
codeunit 3111 "Activity Log Builder"
{
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        ActivityLogBuilderImpl: Codeunit "Activity Log Builder Impl.";

    /// <summary>
    /// Initializes the activity log builder for a specific table and field.
    /// </summary>
    [Scope('OnPrem')]
    procedure Init(TableNo: Integer; FieldNo: Integer; RecSystemId: Guid): Codeunit "Activity Log Builder"
    begin
        ActivityLogBuilderImpl := ActivityLogBuilderImpl.Init(TableNo, FieldNo, RecSystemId);
        exit(this);
    end;

    /// <summary>
    /// Sets the explanation for the activity log entry.
    /// </summary>
    [Scope('OnPrem')]
    procedure SetExplanation(Explanation: Text): Codeunit "Activity Log Builder"
    begin
        ActivityLogBuilderImpl := ActivityLogBuilderImpl.SetExplanation(Explanation);
        exit(this);
    end;

    /// <summary>
    /// Sets the type of the activity log entry.
    /// Allowed values are "AI" for AI-related activities and "AL" for general activities
    /// </summary>
    [Scope('OnPrem')]
    procedure SetType(Type: Enum "Activity Log Type"): Codeunit "Activity Log Builder"
    begin
        ActivityLogBuilderImpl := ActivityLogBuilderImpl.SetType(Type);
        exit(this);
    end;

    /// <summary>
    /// Sets the reference source for the activity log entry.
    /// The reference source can be a page ID and a record reference, which will be converted to a URL.
    /// </summary>
    [Scope('OnPrem')]
    procedure SetReferenceSource(PageId: Integer; var Rec: RecordRef): Codeunit "Activity Log Builder"
    begin
        ActivityLogBuilderImpl := ActivityLogBuilderImpl.SetReferenceSource(PageId, Rec);
        exit(this);
    end;

    /// <summary>
    /// Sets the reference source for the activity log entry.
    /// This can be a URL or any other text that identifies the source of the reference.
    /// </summary>
    [Scope('OnPrem')]
    procedure SetReferenceSource(ReferenceSource: Text): Codeunit "Activity Log Builder"
    begin
        ActivityLogBuilderImpl := ActivityLogBuilderImpl.SetReferenceSource(ReferenceSource);
        exit(this);
    end;

    /// <summary>
    /// Sets the reference title for the activity log entry.
    /// </summary>
    [Scope('OnPrem')]
    procedure SetReferenceTitle(ReferenceTitle: Text): Codeunit "Activity Log Builder"
    begin
        ActivityLogBuilderImpl := ActivityLogBuilderImpl.SetReferenceTitle(ReferenceTitle);
        exit(this);
    end;

    /// <summary>
    /// Logs the activity entry that has been built using the methods of this codeunit.
    /// </summary>
    [Scope('OnPrem')]
    procedure Log()
    begin
        ActivityLogBuilderImpl.Log();
    end;

}