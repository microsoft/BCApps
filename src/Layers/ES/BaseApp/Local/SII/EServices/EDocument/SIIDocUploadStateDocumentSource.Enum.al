// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

#pragma warning disable AL0659 // Accepted: renaming the enum is a breaking change
enum 10755 "SII Doc. Upload State Document Source"
#pragma warning restore AL0659
{
    Extensible = true;

    value(0; "Customer Ledger")
    {
        Caption = 'Customer Ledger';
    }
    value(1; "Vendor Ledger")
    {
        Caption = 'Vendor Ledger';
    }
    value(2; "Detailed Customer Ledger")
    {
        Caption = 'Detailed Customer Ledger';
    }
    value(3; "Detailed Vendor Ledger")
    {
        Caption = 'Detailed Vendor Ledger';
    }
}
