// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

tableextension 11423 "VAT Entry NL" extends "VAT Entry"
{
    keys
    {
        key(Key11400; Type, "Country/Region Code", "VAT Registration No.", "EU 3-Party Trade", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Calculation Type", "Document Type", "Posting Date", "EU Service")
        {
            SumIndexFields = Base;
        }
    }
}
