// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.FixedAsset;

codeunit 13483 "Dep Diff FI Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Table, Database::"FA Posting Group", 'OnInitializeDepreciationDifferenceAccounts', '', false, false)]
    local procedure OnInitializeDepreciationDifferenceAccounts(var FAPostingGroup: Record "FA Posting Group"; DepreciationDifferenceAccount: Code[20]; DepreciationDifferenceBalAccount: Code[20]; var IsHandled: Boolean)
#if not CLEAN30
    var
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
#endif
    begin
        if IsHandled then
            exit;

#if not CLEAN30
        if not DepreciationDifferencesFIFeature.IsEnabled() then
            exit;
#endif
        FAPostingGroup.Validate("Deprec. Difference Account", DepreciationDifferenceAccount);
        FAPostingGroup.Validate("Deprec. Difference Bal Acct", DepreciationDifferenceBalAccount);
        IsHandled := true;
    end;
}
