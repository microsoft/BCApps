// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

/// <summary>
/// Atomic clear-then-rebuild scope for the French derogatory linkage forward corrective upgrade (FR-NFR-003/
/// ITEM-025). This codeunit is intentionally a plain (non-Upgrade) subtype so it can be invoked through
/// Codeunit.Run boolean-context semantics from codeunit "Upgrade Derogatory Linkage": a codeunit whose Subtype is
/// Upgrade cannot be invoked via Codeunit.Run outside the schema synchronization process, so the atomic,
/// rollback-on-failure scope is factored out into this separate codeunit. If any step fails (for example an
/// ambiguous depreciation-book relationship setup), every database change made during this Run - including the
/// clears and corrective upgrade tag - is automatically rolled back by the platform, leaving no partial state.
/// </summary>
codeunit 104104 "Derog. Linkage Corrective Run"
{
    Access = Internal;

    trigger OnRun()
    var
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
    begin
        UpgradeDerogatoryLinkage.ClearAndRelinkConfiguredRelationshipPairs();
    end;
}