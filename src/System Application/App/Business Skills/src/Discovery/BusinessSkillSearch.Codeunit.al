// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Ranks active business skills using native semantic search with privacy approval and current-identity lookup.
/// </summary>
codeunit 4168 "Business Skill Search"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Returns the serialized semantic response for the requested query and result limit.
    /// </summary>
    procedure Search(Query: Text; Top: Integer): Text
    var
        Impl: Codeunit "Business Skill Search Impl.";
    begin
        exit(Impl.Search(Query, Top));
    end;

    /// <summary>
    /// Returns the candidate fields used for semantic ranking.
    /// </summary>
    internal procedure SearchFieldIds(): List of [Integer]
    var
        Impl: Codeunit "Business Skill Search Impl.";
    begin
        exit(Impl.SearchFieldIds());
    end;
}
