// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Analysis;

using Microsoft.Purchases.Vendor;

query 9089 "Purchase by Vendor Group"
{
    Caption = 'Purchase by Vendor Group';
    QueryType = Normal;
    Access = Internal;
    DataAccessIntent = ReadOnly;

    InherentEntitlements = X;
    InherentPermissions = X;

    elements
    {
        dataitem(Vendor_Posting_Group; "Vendor Posting Group")
        {
            column(Code; Code)
            {
            }
            dataitem(Vendor; Vendor)
            {
                DataItemLink = "Vendor Posting Group" = Vendor_Posting_Group.Code;

                filter(Date_Filter; "Date Filter")
                {
                }
                column(Purchases__LCY_; "Purchases (LCY)")
                {
                    Method = Sum;
                }
            }
        }
    }
}
