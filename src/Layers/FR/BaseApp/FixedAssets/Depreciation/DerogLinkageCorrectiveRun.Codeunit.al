// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

/// <summary>
/// Clears and rebuilds historical French derogatory ledger entry links for configured depreciation book
/// relationships. This codeunit has no Upgrade subtype so codeunit "Upgrade Derogatory Linkage" can run it through
/// Codeunit.Run. The clear, validation, rebuild, and upgrade tag update run in one transaction. If any step fails,
/// all changes made by this codeunit are rolled back, leaving no partial state.
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