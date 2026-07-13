// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

tableextension 13421 "VAT Entry FI" extends "VAT Entry"
{
    keys
    {
        // Deprecated FI-legacy index. The former FI VAT Entry override appended "EU Service" to Key4
        // solely to group EU sales into goods vs. services totals. In practice the only consumer is
        // query "VAT Entries Base Amt. Sum", which aggregates via SQL GROUP BY and does not use SIFT,
        // and the base W1 Key4 already carries the same SumIndexFields. The key is therefore retained
        // disabled (no SQL/SIFT index is created) for documentation rather than being silently dropped.
        key(EUServiceFI; Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date", "EU Service")
        {
            Enabled = false;
            SumIndexFields = Base, "Additional-Currency Base";
        }
    }
}
