// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.GeneralLedger.Account;

tableextension 13470 "FA Posting Group DeprDiff FI" extends "FA Posting Group"
{
    fields
    {
        field(13478; "Depreciation Difference Account"; Code[20])
        {
            Caption = 'Depr. Difference Acc.';
            TableRelation = "G/L Account";
            DataClassification = CustomerContent;
        }
        field(13479; "Depreciation Difference Balancing Account"; Code[20])
        {
            Caption = 'Depr. Difference Bal. Acc.';
            TableRelation = "G/L Account";
            DataClassification = CustomerContent;
        }
    }
}
