// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

#if CLEAN30
#if not CLEANSCHEMA33
using System.Upgrade;
#endif
#endif

codeunit 13476 "Dep Diff FI Upgrade Tag"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

#if CLEAN30
#if not CLEANSCHEMA33
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure OnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetUpgradeTag());
    end;
#endif
#endif

    procedure GetUpgradeTag(): Code[250]
    begin
        exit('MS-DepreciationDifferencesFIUpgradeTag-20260711');
    end;
}
