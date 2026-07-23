// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using System.Upgrade;

codeunit 5867 "Upg. Tag Accelerated Depr."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetAcceleratedDepreciationUpgradeTag());
    end;

    internal procedure GetAcceleratedDepreciationUpgradeTag(): Code[250]
    begin
        exit('MS-581204-AcceleratedDepreciationUpgradeTag-20260206');
    end;
}