// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Ledger;

tableextension 13471 "FA Ledger Entry DeprDiff FI" extends "FA Ledger Entry"
{
    fields
    {
        field(13480; "Depreciation Difference Posted"; Boolean)
        {
            Caption = 'Depr. Difference Posted';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key13; "FA No.", "FA Posting Group", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date", "Depreciation Difference Posted")
        {
            SumIndexFields = Amount;
        }
    }
}
