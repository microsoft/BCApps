// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.FixedAsset;

pageextension 13473 "FA PG Card DeprDiff FI" extends "FA Posting Group Card"
{
    layout
    {
        addafter("Maintenance Expense Account")
        {
            field("Depreciation Difference Account"; Rec."Depreciation Difference Account")
            {
                ApplicationArea = FixedAssets;
                ToolTip = 'Specifies the depreciation difference account that is associated with the fixed asset.';
            }
        }
        addafter("Maintenance Bal. Acc.")
        {
            field("Depreciation Difference Balancing Account"; Rec."Depreciation Difference Balancing Account")
            {
                ApplicationArea = FixedAssets;
                ToolTip = 'Specifies the depreciation difference balance account that is associated with the fixed asset.';
            }
        }
    }
}

