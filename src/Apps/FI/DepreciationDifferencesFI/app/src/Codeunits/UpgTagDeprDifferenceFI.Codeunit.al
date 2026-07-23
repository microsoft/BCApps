// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using System.Upgrade;

codeunit 13469 "Upg. Tag Depr. Diff. FI"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetDeprDifferenceFIUpgradeTag());
    end;

    internal procedure GetDeprDifferenceFIUpgradeTag(): Code[250]
    begin
        exit('MS-DeprDifferenceFIUpgradeTag-20260723');
    end;
}
