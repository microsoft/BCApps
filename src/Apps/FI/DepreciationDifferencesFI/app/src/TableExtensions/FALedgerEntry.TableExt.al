// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Ledger;

tableextension 13470 "FA Ledger Entry DeprDiff FI" extends "FA Ledger Entry"
{
    fields
    {
        field(13464; "Depreciation Difference Posted"; Boolean)
        {
            Caption = 'Depr. Difference Posted';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(DepreciationDifferenceFI; "FA No.", "FA Posting Group", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date", "Depreciation Difference Posted")
        {
            SumIndexFields = Amount;
        }
    }
}
