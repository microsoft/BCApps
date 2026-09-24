// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using System.Upgrade;

/// <summary>
/// Clears and rebuilds historical French derogatory ledger entry links for configured depreciation book
/// relationships for an explicitly invoked operational repair. Feature and app upgrades call the shared
/// procedure directly, without Codeunit.Run, to preserve the enclosing migration transaction.
/// </summary>
codeunit 104104 "Derog. Linkage Corrective Run"
{
    Access = Internal;

    trigger OnRun()
    var
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()) then
            exit;

        UpgradeDerogatoryLinkage.RunCorrectiveUpgrade();
    end;
}