// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.GeneralLedger.Account;

tableextension 13469 "FA Posting Group DeprDiff FI" extends "FA Posting Group"
{
    fields
    {
        field(13462; "Deprec. Difference Account"; Code[20])
        {
            Caption = 'Depr. Difference Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(13463; "Deprec. Difference Bal Acct"; Code[20])
        {
            Caption = 'Depr. Difference Bal. Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
    }
}
