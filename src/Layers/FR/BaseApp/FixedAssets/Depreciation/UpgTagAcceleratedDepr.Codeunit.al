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
        PerCompanyUpgradeTags.Add(GetDerogatoryLinkageUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDerogatoryLinkageCorrectiveUpgradeTag());
    end;

    internal procedure GetAcceleratedDepreciationUpgradeTag(): Code[250]
    begin
        exit('MS-581204-AcceleratedDepreciationUpgradeTag-20260206');
    end;

    internal procedure GetDerogatoryLinkageUpgradeTag(): Code[250]
    begin
        exit('MS-581204-DerogatoryLinkageUpgradeTag-20260730');
    end;

    internal procedure GetDerogatoryLinkageCorrectiveUpgradeTag(): Code[250]
    begin
        exit('MS-581204-DerogatoryLinkageCorrectiveUpgradeTag-20260805');
    end;
}