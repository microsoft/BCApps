// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.FixedAssets.Depreciation;

pageextension 13472 "FA Posting Group Card DeprDiff" extends "FA Posting Group Card"
{
    layout
    {
        addafter("Maintenance Expense Account")
        {
            field("Deprec. Difference Account"; Rec."Deprec. Difference Account")
            {
                ApplicationArea = FixedAssets;
                ToolTip = 'Specifies the depreciation difference account that is associated with the fixed asset.';
#if not CLEAN30
                Visible = DepreciationDifferencesEnabled;
#endif
            }
        }
        addafter("Maintenance Bal. Acc.")
        {
            field("Deprec. Difference Bal Acct"; Rec."Deprec. Difference Bal Acct")
            {
                ApplicationArea = FixedAssets;
                ToolTip = 'Specifies the depreciation difference balance account that is associated with the fixed asset.';
#if not CLEAN30
                Visible = DepreciationDifferencesEnabled;
#endif
            }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify("Depr. Difference Acc.")
        {
            Visible = not DepreciationDifferencesEnabled;
        }
        modify("Depr. Difference Bal. Acc.")
        {
            Visible = not DepreciationDifferencesEnabled;
        }
#pragma warning restore AL0432
#endif
    }

#if not CLEAN30
    trigger OnOpenPage()
    var
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
    begin
        DepreciationDifferencesEnabled := DepreciationDifferencesFIFeature.IsEnabled();
    end;

    var
        DepreciationDifferencesEnabled: Boolean;
#endif
}
