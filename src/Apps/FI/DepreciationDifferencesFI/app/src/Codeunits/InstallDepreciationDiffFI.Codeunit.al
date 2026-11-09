#if CLEAN30
#if not CLEANSCHEMA33
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

codeunit 13484 "Install Depreciation Diff. FI"
{
    Access = Internal;
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerCompany()
    var
        UpgradeDepreciationDiffFI: Codeunit "Upgrade Depreciation Diff. FI";
    begin
        UpgradeDepreciationDiffFI.UpgradeDepreciationDifferencesFI();
    end;
}
#endif
#endif
