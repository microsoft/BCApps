// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

tableextension 13413 "VAT Entry FI" extends "VAT Entry"
{
    keys
    {
        key(EUServiceFI; Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date", "EU Service")
        {
            SumIndexFields = Base, "Additional-Currency Base";
        }
    }
}