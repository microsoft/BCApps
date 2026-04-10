// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.Vendor;

query 134 "OCR Vendors"
{
    Caption = 'OCR Vendors';

    elements
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableFilter = Name = filter(<> '');
            column(Id; SystemId)
            {
            }
            column(No; "No.")
            {
            }
            column(VAT_Registration_No; "VAT Registration No.")
            {
            }
            column(Name; Name)
            {
            }
            column(Address; Address)
            {
            }
            column(Post_Code; "Post Code")
            {
            }
            column(City; City)
            {
            }
            column(Phone_No; "Phone No.")
            {
            }
            column(Blocked; Blocked)
            {
            }
            column(ModifiedAt; SystemModifiedAt)
            {
            }
        }
    }
}

